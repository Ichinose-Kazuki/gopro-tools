const gpmfExtract = require('gpmf-extract');
const goproTelemetry = require(`gopro-telemetry`);
const fs = require('fs');

// Not much difference in output file size, disabled
// const keysInGPX = ['GPS5', 'GPS9'];

const args = process.argv.slice(2);
const input_file = fs.readFileSync(args[0]);
const output_path = args[1];

gpmfExtract(input_file)
  .then(extracted => {
    goproTelemetry(extracted, {}, telemetry => {
      // keysInGPX.forEach(key => {
      //   streams = telemetry["1"]["streams"];
      //   if (key in streams) {
      //     delete streams[key];
      //   }
      // });
      fs.writeFileSync(output_path, JSON.stringify(telemetry));
    });
  })
  .catch(error => console.error(error));
