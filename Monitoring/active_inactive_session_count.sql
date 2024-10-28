select count(*) as "Count", username, status
from v$session where username is not null
group by username,status 
order by username,status;