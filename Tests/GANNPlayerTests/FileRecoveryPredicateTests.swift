import XCTest
@testable import GANNPlayer

/// Проверки чистых функций нового поиска: сборка предиката и экранирование.
/// Сам обход диска и mdfind не тестируются — они требуют реальной файловой системы
/// и индекса Spotlight, а вот предикат собирается детерминированно.
final class FileRecoveryPredicateTests: XCTestCase {

    func testEscapesBackslashAndQuote() {
        XCTAssertEqual(FileRecovery.escapeForPredicate("a\\b"), "a\\\\b")
        XCTAssertEqual(FileRecovery.escapeForPredicate("say \"hi\""), "say \\\"hi\\\"")
        XCTAssertEqual(FileRecovery.escapeForPredicate("plain.mp3"), "plain.mp3")
    }

    func testSizePredicateContainsNameAndSize() {
        let p = FileRecovery.sizePredicate(name: "Track 01.flac", size: 12_345_678)
        XCTAssertTrue(p.contains("kMDItemFSName"))
        XCTAssertTrue(p.contains("kMDItemFSSize == 12345678"))
        XCTAssertTrue(p.hasSuffix("cd"), "сравнение имени должно быть без учёта регистра")
        XCTAssertTrue(p.contains("Track 01.flac"))
    }

    func testNamePredicateHasNoSize() {
        let p = FileRecovery.namePredicate(name: "Song.wav")
        XCTAssertFalse(p.contains("kMDItemFSSize"))
        XCTAssertTrue(p.contains("Song.wav"))
    }

    /// Имя с кавычкой не должно ломать предикат — иначе mdfind вернёт ошибку разбора.
    func testPredicateSurvivesQuoteInName() {
        let p = FileRecovery.sizePredicate(name: "He said \"go\".mp3", size: 1024)
        let quotes = p.filter { $0 == "\"" }.count
        XCTAssertEqual(quotes, 2, "кавычек в предикате должно остаться ровно две — обрамляющие")
        XCTAssertTrue(p.contains("\\\"go\\\""))
    }
}
