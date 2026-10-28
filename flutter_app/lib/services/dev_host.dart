/// Where a debug build finds the backend: the Mac that runs `make run`.
///
/// Android reaches the Mac's port through `adb reverse tcp:3001 tcp:3001`
/// (done by `make run`), so it keeps its own `localhost`. An iPhone has no
/// such tunnel over USB, so it uses the Mac's Bonjour name on the same Wi‑Fi,
/// passed by the Makefile as `--dart-define=API_HOST=<name>.local`; the
/// simulator resolves it too. Without the define: `localhost`, as before.
const String apiHostDefine = String.fromEnvironment('API_HOST', defaultValue: 'localhost');

String devApiHost({required bool android, String define = apiHostDefine}) => android ? 'localhost' : define;
