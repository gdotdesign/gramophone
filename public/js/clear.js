fs = require('fs');
path = process.env.HOME+"/.config/Gramophone/cookies"
if(fs.existsSync(path))
  fs.unlinkSync(path)