from dotenv import load_dotenv
import os
load_dotenv()

#!/usr/bin/env python
# coding: utf-8

# In[ ]:





# In[3]:


# this is our table
import pandas as pd
df=pd.read_csv('netflix_titles.csv')
df.head()



# In[16]:


df.dtypes


# In[40]:


from sqlalchemy import create_engine
engine=create_engine('postgresql+psycopg2://${DB_USER}:${DB_PASSWORD}@${DB_HOST}:${DB_PORT}/${DB_NAME}netflix_db')

df.to_sql('netflix_data', con=engine, index=False, if_exists='append')    


# In[39]:


max(df.description.dropna().str.len())


# In[5]:


df.isna().head(10)

