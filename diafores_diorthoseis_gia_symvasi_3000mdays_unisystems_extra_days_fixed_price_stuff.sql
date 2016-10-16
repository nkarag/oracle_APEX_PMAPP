drop table FIXED_PRICE_3000_UNISYSTEMS;


select * --sum(m_days), sum(to_number(mdays))
from FIXED_PRICE_3000_UNISYSTEMS join fixed_price_prjs_from_xls on (cr_id = name_description);


alter table fixed_price_prjs_from_xls modify company varchar2(30);

update fixed_price_prjs_from_xls t
set company = 'OTHER'
where name_description in (
  select name_description
  from fixed_price_prjs_from_xls
  minus
  select cr_id
  from FIXED_PRICE_3000_UNISYSTEMS
);


update fixed_price_prjs_from_xls t
set company = 'UNISYSTEMS'
where company is null;

commit;


select name_description, to_number(mdays)
from fixed_price_prjs_from_xls
where
  company = 'UNISYSTEMS'
  minus
select t1.cr_id, m_days
from  FIXED_PRICE_3000_UNISYSTEMS t1 join fixed_price_prjs_from_xls on (cr_id = name_description);


select t2.name_description, t2.mdays, t1.m_days
from FIXED_PRICE_3000_UNISYSTEMS t1 join fixed_price_prjs_from_xls t2 on (cr_id = name_description)
where
  t1.m_days <> to_number(t2.mdays);

merge into fixed_price_prjs_from_xls t
  using(
    select t2.name_description, t2.mdays, t1.m_days
    from FIXED_PRICE_3000_UNISYSTEMS t1 join fixed_price_prjs_from_xls t2 on (cr_id = name_description)
    where
      t1.m_days <> to_number(t2.mdays)
  ) s ON (t.name_description = s.name_description)
WHEN MATCHED THEN UPDATE
  set t.mdays = s.m_days;
  
  commit;
  
  
update fixed_price_prjs_from_xls t
set company = 'non-Unisystems'  
where company = 'OTHER';

commit;
  
  