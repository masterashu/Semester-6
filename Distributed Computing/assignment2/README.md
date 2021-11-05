# 
## Dependencies
> Note `python3` and `pip3` is required
```
pip install celery, requests, bs4, flask
```
## Part 1
```
python crawler.py
```

# Part 2
Run in different terminals
Install rabbitMQ
```
sudo apt install rabbitmq-server
```
```
celery -A fetcher workers -l INFO
```
```
python fetcher.py
```

# Part 3
```
celery -A parser workers -l INFO
```
```
python parser.py
```

# Part 4
```
export FLASK_APP=app.py
flask run
```

go to localhost:5000/

Note: I have included a dummy document with very few question just for easy running.
Remove the `info` and `data` directories for freshdata.
