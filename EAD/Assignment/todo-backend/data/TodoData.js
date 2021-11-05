const Todo = require('../models/TodoScheme');

class TodoData {
    constructor(model) {
        this.model = model;
    }

    create(title) {
        const newTodo = { title, done: false };
        const todo = new this.model(newTodo);
        return todo.save();
    }

    findAll() {
        return this.model.find();
    }

    findById(id) {
        return this.model.findById(id);
    }

    updateStatusById(id, object) {
        const query = { _id: id };
        return this.model.findOneAndUpdate(query, {
            $set: {
                done:
                    object.done
            }
        });
    }
}

module.exports = new TodoData(Todo);
