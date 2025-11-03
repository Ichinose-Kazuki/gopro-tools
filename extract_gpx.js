const gpmfExtract = require('gpmf-extract');
const goproTelemetry = require(`gopro-telemetry`);
const fs = require('fs');

const args = process.argv.slice(2);
const input_file = fs.readFileSync(args[0]);
const output_path = args[1];

gpmfExtract(input_file)
  .then(extracted => {
    goproTelemetry(extracted, {
      preset: "gpx"
    }, telemetry => {
      fs.writeFileSync(output_path, telemetry);
    });
  })
  .catch(error => console.error(error));
