import XCTest
@testable import GANNPlayer

final class UndoStackTests: XCTestCase {

    private func snapshot(_ name: String, action: String = "тест") -> UndoStack.Snapshot {
        UndoStack.Snapshot(playlists: [Playlist(name: name, order: 0)],
                           selectedPlaylistID: nil,
                           actionName: action)
    }

    func testStartsEmpty() {
        let stack = UndoStack()
        XCTAssertFalse(stack.canUndo)
        XCTAssertFalse(stack.canRedo)
        XCTAssertNil(stack.undoTitle)
    }

    func testRecordMakesUndoAvailable() {
        var stack = UndoStack()
        stack.record(snapshot("A", action: "удаление трека"))
        XCTAssertTrue(stack.canUndo)
        XCTAssertEqual(stack.undoTitle, "удаление трека")
        XCTAssertFalse(stack.canRedo)
    }

    func testUndoMovesToRedo() {
        var stack = UndoStack()
        stack.record(snapshot("A"))
        let target = stack.undo(current: snapshot("B"))
        XCTAssertEqual(target?.playlists.first?.name, "A")
        XCTAssertFalse(stack.canUndo)
        XCTAssertTrue(stack.canRedo)
    }

    func testRedoRestores() {
        var stack = UndoStack()
        stack.record(snapshot("A"))
        let undone = stack.undo(current: snapshot("B"))
        XCTAssertEqual(undone?.playlists.first?.name, "A")
        let redone = stack.redo(current: snapshot("A"))
        XCTAssertEqual(redone?.playlists.first?.name, "B")
        XCTAssertTrue(stack.canUndo)
        XCTAssertFalse(stack.canRedo)
    }

    /// Новое действие после отмены обнуляет ветку повтора — иначе ⌘Z вернул бы
    /// состояние, которого уже не существует.
    func testNewRecordClearsRedo() {
        var stack = UndoStack()
        stack.record(snapshot("A"))
        _ = stack.undo(current: snapshot("B"))
        XCTAssertTrue(stack.canRedo)
        stack.record(snapshot("C"))
        XCTAssertFalse(stack.canRedo)
    }

    func testLimitDropsOldest() {
        var stack = UndoStack(limit: 3)
        for name in ["A", "B", "C", "D"] { stack.record(snapshot(name)) }
        XCTAssertEqual(stack.undoStack.count, 3)
        // Самое старое («A») вытеснено: первый откат возвращает «C».
        XCTAssertEqual(stack.undo(current: snapshot("E"))?.playlists.first?.name, "C")
    }

    func testUndoOnEmptyReturnsNil() {
        var stack = UndoStack()
        XCTAssertNil(stack.undo(current: snapshot("A")))
    }

    func testRemoveAllClearsBothStacks() {
        var stack = UndoStack()
        stack.record(snapshot("A"))
        _ = stack.undo(current: snapshot("B"))
        stack.removeAll()
        XCTAssertFalse(stack.canUndo)
        XCTAssertFalse(stack.canRedo)
    }
}
