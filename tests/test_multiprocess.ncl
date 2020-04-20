
from multiprocessing import Process
import time

def worker():
    time.sleep(3)

p = Process(target=worker)
p.start()
for i in range(6):
    print("is_alive(): "+str(p.is_alive()))
    time.sleep(1)
