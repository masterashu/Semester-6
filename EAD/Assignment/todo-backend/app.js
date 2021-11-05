const express = require('express');
const app = express();

app.set('view engine', 'ejs');
app.use('/static', express.static('public'));
const bodyParser = require('body-parser');
app.use(bodyParser.urlencoded({ extended: true }))
app.use(bodyParser.json())


var router = express.Router();
const todos = require('./routes/todos');
app.use('/todos', todos);

app.get('/', (req, res) => {
    res.send('Hello World!');
});

app.listen(3000, () => console.log('Server Up and running'));
