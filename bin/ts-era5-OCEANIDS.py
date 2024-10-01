#!/usr/bin/env python3
import time, warnings,requests,json
import pandas as pd
#import functions as fcts
import warnings
warnings.simplefilter(action='ignore', category=FutureWarning)
# SmarMet-server timeseries query to fetch ERA5 training data for ML
# remember to: conda activate xgb 

startTime=time.time()
'''
http://desm.harvesterseasons.com:8080/timeseries?bbox=24.9459,60.45867,25.4459,59.95867&param=utctime,latitude,longitude,T2-K:ERA5:5021:1:0:1:0&starttime=20150101T000000Z&endtime=20150105T000000Z&hour=00&format=debug&precision=double&tz=utc&timeformat=sql
'''

y_start='2015'
y_end='2022'
source1='era5.apps.ocp.fmi.fi' # server for timeseries query 2013-2019 
source2='desm.harvesterseasons.com:8080' # server for timeseries query 2020-2023
bbox='24.9459,60.45867,25.4459,59.95867' # Vuosaari harbor region, 4 grid points
predictors1 = 'T-K:ERA5:26:1:0:1,U-MS:ERA5:26:1:0:1'
predictors2 = 'T2-K:ERA5:5021:1:0:1:0,U10-MS:ERA5:5021:1:0:1:0'
start='20150101T000000Z'
end='20150105T000000Z'
tstep='3h'
# Timeseries query for source1
query='https://'+source1+'/timeseries?bbox='+bbox+'&param=utctime,latitude,longitude,'+predictors1+'&starttime='+start+'&endtime='+end+'&timestep='+tstep+'&format=json&precision=double&tz=utc&timeformat=sql'
print(query)

response=requests.get(url=query)
results_json=json.loads(response.content)
print(results_json)    

# Timeseries query for source2
query='http://'+source2+'/timeseries?bbox='+bbox+'&param=utctime,latitude,longitude,'+predictors2+'&starttime='+start+'&endtime='+end+'&timestep='+tstep+'&format=json&precision=double&tz=utc&timeformat=sql'
print(query)





executionTime=(time.time()-startTime)
print('Execution time in minutes: %.2f'%(executionTime/60))