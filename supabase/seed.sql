insert into public.service_categories (name_en, name_ur, description_en, description_ur)
values
  ('Bandage', 'پٹی', 'Basic bandage and wound dressing support.', 'بنیادی پٹی اور زخم کی دیکھ بھال۔'),
  ('Injection', 'انجیکشن', 'At-home injection service by a verified worker.', 'تصدیق شدہ ورکر کے ذریعے گھر پر انجیکشن کی سہولت۔'),
  ('Drip', 'ڈرپ', 'IV drip support where medically appropriate.', 'طبی ضرورت کے مطابق ڈرپ کی سہولت۔'),
  ('Blood Sample', 'خون کا نمونہ', 'Blood sample collection from home.', 'گھر سے خون کا نمونہ لینے کی سہولت۔'),
  ('Stitches Support', 'ٹانکوں کی دیکھ بھال', 'Basic stitches care and support.', 'ٹانکوں کی بنیادی دیکھ بھال۔'),
  ('Basic Checkup', 'بنیادی معائنہ', 'General basic health checkup at home.', 'گھر پر بنیادی صحت کا معائنہ۔'),
  ('Wound Care', 'زخم کی دیکھ بھال', 'Basic wound cleaning and care.', 'زخم کی بنیادی صفائی اور دیکھ بھال۔')
on conflict do nothing;
