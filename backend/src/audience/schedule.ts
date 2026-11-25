/**
 * Keeps something downloaded up to date: a first run a moment after start,
 * then again every `every` after a success, and every `retry` after a
 * failure — a download that fails when the server starts must not leave the
 * counter without its data for a day. The first run is not immediate, so
 * that a server restarting in a loop does not ask the source each time.
 *
 * `task` says whether it worked; a task that throws did not.
 */
export function keepFresh(task: () => Promise<boolean>, times: {
  first: number;
  every: number;
  retry: number;
  setTimer?: (run: () => void, ms: number) => void;
}): void {
  const setTimer = times.setTimer ?? ((run: () => void, ms: number) => { setTimeout(run, ms).unref(); });
  const run = () => {
    task().catch(() => false).then((worked) => setTimer(run, worked ? times.every : times.retry));
  };
  setTimer(run, times.first);
}
