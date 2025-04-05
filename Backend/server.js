const {app} = require('./app.js');
const connectDB = require('./dbconnection.js');
const PORT = process.env.PORT || 8080;
connectDB()
app.listen(PORT, '0.0.0.0', () => {
  console.log(`Server running on ${PORT}`);
});
