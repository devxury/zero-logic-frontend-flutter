# Contributing to Zero-Logic Frontend

First off, thanks for taking the time to contribute! 🎉

The goal of this project is to prove that the Frontend can be 100% dumb and controlled by the Backend.

## 🧠 The Philosophy
Before contributing, remember: **We do not write UI logic in Flutter.**
If you want to change the color of a button, you edit the Python Backend JSONs, not the Dart code.

## 🛠 How to Contribute

### Backend (The Brain)
We love contributions here!
*   **New Components:** Add new schemas to `ui_fragments.json`.
*   **Theming:** Create new themes in `sys_themes.json`.
*   **Logic:** Improve the FastAPI resolvers.

### Frontend (The Muscle)
Only touch the Flutter code if:
*   You are optimizing the rendering engine.
*   You are fixing a crash in the parser.
*   You are adding support for a new native primitive (e.g., a Map or Video Player).

## 流程 Pull Request Process
1.  Fork the repo and create your branch from `main`.
2.  If you've added code that should be tested, add tests.
3.  Ensure your code lints.
4.  Issue that Pull Request!

## 🐛 Reporting Bugs
Please include:
*   The JSON payload causing the error.
*   Screenshots of the broken UI.
*   Logs from the Flutter console.

Happy Coding! 🚀
