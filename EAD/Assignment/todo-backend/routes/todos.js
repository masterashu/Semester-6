const express = require('express');
let app = express.Router();
const dataRepo = require('../data/TodoData');
const cors = require("cors");
app.use(cors());
app.get("/", async (req, res, next) => {
    try {
        const todos = await dataRepo.findAll();
        console.log("todos are " + todos);
        return res.status(200).json(todos);
    } catch (err) {
        next({ status: 400, message: "failed to get todos" });
    }
});
app.post("/", async (req, res, next) => {
    try {
        const todo = await dataRepo.create(req.body.newtodo);
        return res.status(200).json(todo);
        return success(res, todo);
    } catch (err) {
        next({ status: 400, message: "failed to create todo" });
    }
});
app.put("/:id", async (req, res, next) => {
    try {
        const todo = { done: req.body.done };
        const todoPut = await
            dataRepo.updateStatusById(req.params.id.substring(1), todo);
        return res.status(200).json(todoPut); 3
    } catch (err) {
        next({ status: 400, message: "failed to update todo" });
    }
});
app.delete("/:id", async (req, res, next) => {
    try {
        const todoDelete = await
            dataRepo.deleteById(req.params.id.substring(1));
        return res.status(204);
    } catch (err) {
        next({ status: 400, message: "failed to delete todo" });
    }
});
module.exports = app
