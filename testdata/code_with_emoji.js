// Sample code file with long lines and emoji in comments

// 🚀 Performance-critical path — do not add unnecessary allocations here
function processItems(items) {
  // TODO: 🔧 fix edge case where items is null
  return items.map(x => x * 2);
}

// This function has an extremely long comment that goes way past the typical line length limit and tests how the editor renders long comment lines without wrapping or truncating the content in unexpected ways
function longCommentFunction() {
  return 42;
}

const a = 1; const b = 2; const c = 3; const d = 4; const e = 5; const f = 6; const g = 7; const h = 8; const i = 9; const j = 10; const k = 11; const l = 12;

// Emoji in string literals
const greetings = {
  english: "Hello, World! 👋",
  japanese: "こんにちは、世界！ 🌸",
  arabic: "مرحبا بالعالم! 🌙",
  emoji_only: "🎉🎊🥳🎈🎁🎀",
  mixed: "Status: ✅ | Priority: 🔴 | Assigned: 👤 | Due: 📅 2024-12-31",
};

// Long string concatenation on one line
const longString = "part one " + "part two " + "part three " + "part four " + "part five " + "part six " + "part seven " + "part eight " + "part nine " + "part ten";

// URL that is very long
// https://www.example.com/some/very/long/path/to/a/resource?with=many&query=parameters&that=make&the=url&extremely&long=true&and=hard&to=read&in=a&narrow=terminal

// Column alignment test (emoji should be 2 wide):
// Name         | Age | Status
// -------------|-----|-------
// Alice        |  30 | ✅
// 田中太郎     |  25 | 🔄
// محمد علي     |  35 | ❌
// 😀😁😂      |  99 | ⭐

/*
 * Multi-line block comment with long lines and various unicode content:
 * This is the first line of the block comment which contains some normal ASCII text.
 * This is the second line which contains some emoji: 🎯 🏆 💡 🔑 🗝️ 🔒 🔓 🛡️ ⚔️ 🗡️ 🏹 🪃
 * This is a very long third line of the block comment that extends well past 80 columns and tests rendering of wrapped content within a block comment structure in the editor display.
 * CJK line: 这是一个包含中文字符的注释行，用于测试编辑器如何处理混合内容的长注释行渲染。
 */
