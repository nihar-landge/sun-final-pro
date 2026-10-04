'use strict';

const { app } = require('./server');

const PORT = Number(process.env.PORT || 8090);

app.listen(PORT, () => {
  // eslint-disable-next-line no-console
  console.log(`civicpulse-email-service listening on :${PORT}`);
});
