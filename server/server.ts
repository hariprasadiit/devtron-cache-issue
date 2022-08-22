import { server as superstatic } from 'superstatic';
import { readFileSync } from 'fs';

const host: string = process.env.HOST ?? '0.0.0.0';
const port: number = ~~(process.env.PORT || 1339);

const app = superstatic({
  port,
  host,
  compression: true,
  config: `${process.cwd()}/config/superstatic.json`,
  // Made available at path  `/__/env.json`
  cwd: process.cwd(),
});

app.use('/health', (req, res) => {
  res.setHeader('Content-Type', 'application/json');
  res.end(JSON.stringify({ ok: true }));
});

const server = app.listen(() => {
  console.log('superstatic is running on port:', port);
});

//handle OS signals for graceful exit
[
  `exit`,
  `SIGINT`,
  `SIGUSR1`,
  `SIGUSR2`,
  `uncaughtException`,
  `SIGTERM`,
].forEach((eventType) => {
  //ts-ignore
  process.on(eventType as any, (...args: any[]) => {
    if (server.listening)
      server.close((err) => {
        console.warn('Could not close http server gracefully', err);
      });
    // print uncaught exceptions to stderr
    if (eventType === 'uncaughtException')
      console.error(
        `Caught exception: ${args[0]}\n` + `Exception origin: ${args[1]}`
      );

    if (eventType !== 'exit') process.exit();
  });
});
