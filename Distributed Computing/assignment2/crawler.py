from bs4 import BeautifulSoup
import requests
import urllib
tag = 'python'
max_posts = 50
URL = 'https://stackoverflow.com'
BASE_URL = f'{URL}/questions/tagged/{tag}?pagesize={max_posts}'
def get_url():
    url = urllib.parse.urlparse(BASE_URL)
    query = dict(urllib.parse.parse_qsl(url.query))
    query.update({'page': page})
    url = url._replace(query=urllib.parse.urlencode(query))
    return urllib.parse.urlunparse(url)
classname = 'question-hyperlink'
questions_file = open('questions.txt', 'w')
page = 1
documents_crawled = 0
while documents_crawled < 100:
    res = requests.get(get_url())
    html = res.text
    soup = BeautifulSoup(html)
    try:
        questions_link = soup.find(id='questions').find_all('a', attrs={'class': classname})
        for question in questions_link:
            questions_file.write('https://stackoverflow.com' + question.attrs['href'] + '\n')
        documents_crawled += len(questions_link)
        print('Added', len(questions_link), 'Questions to the list')
    except:
        print('Failed.\nRetrying')
    page += 1
questions_file.close()
