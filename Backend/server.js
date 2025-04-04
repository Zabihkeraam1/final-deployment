const {app} = require('./app.js');
const connectDB = require('./dbconnection.js');
const port = 3001;
connectDB()
app.listen(port, () => {
    console.log(`API server running on http://localhost:${port}`);
  });