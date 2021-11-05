from celery import Celery
import requests
import time
import urllib
from pprint import pprint as print
from json import dumps
from uuid import uuid4

import os
BASE_DIR = os.getcwd()
PAGES_DIR = os.getcwd() + '/data'
if not os.path.exists(PAGES_DIR):
    os.makedirs(PAGES_DIR)

KEY = 'TchQeZI6Oi1Lh6Ckq5DUtg(('
app = Celery('fetcher', broker='pyamqp://guest@localhost//')

def get_url(questions_links, page=1):
    ids = ';'.join(list(map(lambda x: x.split('/')[4], questions_links)))
    base_url = f'https://api.stackexchange.com/2.2/questions/{ids}'
    url = urllib.parse.urlparse(base_url)
    query = dict(order='desc', sort='activity', key=KEY, site='stackoverflow', **{'filter':'!)TIzdW64e.WAJj7_MxDO79L7.0zdKS6VeaO)s(ByEn0bFqujp5GjOj1d*'})
    query.update({'page': page})
    url = url._replace(query=urllib.parse.urlencode(query))
    return urllib.parse.urlunparse(url)

def get_related(questions_links, page=1):
    ids = ';'.join(list(map(lambda x: x.split('/')[4], questions_links)))
    base_url = f'https://api.stackexchange.com/2.2/questions/{ids}/related/'
    url = urllib.parse.urlparse(base_url)
    query = dict(order='desc', sort='activity', key=KEY, site='stackoverflow', **{'filter':'!)TIzdW64e.WAJj7_MxDO79L7.0zdKS6WWds-pFnldWgGbLdoft9f*s_)y'})
    query.update({'page': page})
    url = url._replace(query=urllib.parse.urlencode(query))
    return urllib.parse.urlunparse(url)

from itertools import zip_longest

def grouper(iterable, n, fillvalue=None):
    args = [iter(iterable)] * n
    return zip_longest(*args, fillvalue=fillvalue)

@app.task
def get_pages(questions_links, index):
    page = 0
    questions = []
    data = {'has_more': True}
    error = 0
    while data['has_more']:
        time.sleep(1)
        try:
            page = page + 1
            try:    
                url = get_url(questions_links, page)
                res = requests.get(url)
                data = res.json()
            except Exception as e:
                error = error + 1
                if error >= 5:
                    print(e)
                    print(e.args)
                    if res:
                        print(f'{res.status_code}, {res.text}')
                    print(f'Skipping... index {index}')
                    with open(f'{BASE_DIR}/failed.txt', 'a') as failed:
                        failed.write(get_url(questions_links) + '/n')
                    break
                time.sleep(1)
            # print(f'Writing page no. {data["page"]} having {len(data["items"])} in index: {index} questions to the file.')
            questions.extend(data['items'])
        except KeyError:
            time.sleep(2)
        except Exception as e:
            print(e)
            print(e.args)
            error = error + 1
            # print("Some error occured")
            if error >= 5:
                print(f'Skipping... index {index}')
                with open(f'{BASE_DIR}/failed.txt', 'a') as failed:
                    failed.write(get_url(questions_links) + '/n')
                break
            continue
        
    df = open(f'{PAGES_DIR}/df-{index}-{str(uuid4())}.json', 'w')
    df.write(dumps(questions))
    df.close()
    print(f"Index {index} completed")


def main():
    with open('questions.txt', 'r') as f:
        pages_links = f.readlines()
    for index, pages in enumerate(grouper(pages_links[:5000], 100)):
        try:
            pages = list(filter(lambda x: x != None, pages))
            get_pages.delay(pages, index)
        except:
            time.sleep(10)


if __name__ == '__main__':
    main()
