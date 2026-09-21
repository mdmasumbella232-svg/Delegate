-- ============================================================
-- BCS Quiz App — Cloudflare D1 Schema & Seed Data
-- Run: wrangler d1 execute bcs-quiz-db --file=schema.sql
-- ============================================================

-- Drop & recreate for clean migrations
DROP TABLE IF EXISTS attempts;
DROP TABLE IF EXISTS scores;
DROP TABLE IF EXISTS questions;

-- ── Questions ───────────────────────────────────────────────
CREATE TABLE questions (
  id           INTEGER PRIMARY KEY,
  exam_key     TEXT    NOT NULL DEFAULT '10th_bcs',
  subject      TEXT    NOT NULL,
  question_text TEXT   NOT NULL,
  opt_a        TEXT    NOT NULL,
  opt_b        TEXT    NOT NULL,
  opt_c        TEXT    NOT NULL,
  opt_d        TEXT    NOT NULL,
  correct_ans  INTEGER NOT NULL CHECK(correct_ans BETWEEN 0 AND 3),
  note         TEXT
);

-- ── Scores (leaderboard) ────────────────────────────────────
CREATE TABLE scores (
  id             INTEGER PRIMARY KEY AUTOINCREMENT,
  exam_key       TEXT    NOT NULL DEFAULT '10th_bcs',
  player_name    TEXT    NOT NULL DEFAULT 'অজ্ঞাত',
  subject_filter TEXT    NOT NULL DEFAULT 'all',
  correct        INTEGER NOT NULL DEFAULT 0,
  wrong          INTEGER NOT NULL DEFAULT 0,
  skipped        INTEGER NOT NULL DEFAULT 0,
  total          INTEGER NOT NULL DEFAULT 0,
  time_taken     INTEGER NOT NULL DEFAULT 0,
  created_at     TEXT    NOT NULL DEFAULT (datetime('now'))
);

CREATE INDEX idx_scores_correct ON scores(correct DESC);
CREATE INDEX idx_scores_created ON scores(created_at DESC);

-- ── Attempts (per-question detail per session) ───────────────
CREATE TABLE attempts (
  id          INTEGER PRIMARY KEY AUTOINCREMENT,
  score_id    INTEGER NOT NULL REFERENCES scores(id) ON DELETE CASCADE,
  question_id INTEGER NOT NULL,
  user_answer INTEGER NOT NULL DEFAULT -1,
  is_correct  INTEGER NOT NULL DEFAULT 0
);

CREATE INDEX idx_attempts_score ON attempts(score_id);

-- ============================================================
-- SEED: All 100 BCS 10th Preliminary Questions
-- ============================================================

-- ── BANGLA (1-18) ───────────────────────────────────────────
INSERT INTO questions VALUES(1,'bangla','''আনারস'' এবং ''চাবি'' শব্দ দুটি বাংলা ভাষা গ্রহণ করেছে-','পর্তুগিজ ভাষা হতে','আরবি ভাষা হতে','দেশি ভাষা হতে','ওলন্দাজ ভাষা হতে',0,NULL);
INSERT INTO questions VALUES(2,'bangla','শুদ্ধ বানান কোনটি?','মুমুর্ষ','মুমূর্ষু','মূমুর্ষ','মূমূর্ষু',1,NULL);
INSERT INTO questions VALUES(3,'bangla','শুদ্ধ বাক্য কোনটি?','দুর্বলতাবশত অনাথিনী বেসে পড়ল','দুর্বলতাবশত অনাথিনী বসে পড়ল','দুর্বলতাবশত অনাথা বসে পড়ল','দুর্বলতাবশতঃ অনাথা বসে পড়ল',2,NULL);
INSERT INTO questions VALUES(4,'bangla','সমাস/চর্যাবলী দোষমুক্ত কোনটি?','শবপোড়া','মড়াদাহ','শবদাহ','শবমড়া',2,NULL);
INSERT INTO questions VALUES(5,'bangla','''কবর'' নাটকটির লেখক-','জসীমউদ্দীন','নজরুল ইসলাম','মুনীর চৌধুরী','দ্বিজেন্দ্রলাল রায়',2,NULL);
INSERT INTO questions VALUES(6,'bangla','বাংলায় কোরআন শরীফের প্রথম অনুবাদক কে?','কেশবচন্দ্র সেন','মওলানা মনিরুজ্জামান ইসলামাবাদী','মওলানা আকরম খাঁ','গিরিশচন্দ্র সেন',3,NULL);
INSERT INTO questions VALUES(7,'bangla','''রত্নাকর'' শব্দটির সন্ধি-বিচ্ছেদ-','রত্ন + কর','রত্না + কর','রত্ন + আকর','রত্না + আকর',2,NULL);
INSERT INTO questions VALUES(8,'bangla','ক্রিয়াপদের মূল অংশকে বলা হয়-','বিভক্তি','ধাতু','প্রত্যয়','কৃৎ',1,NULL);
INSERT INTO questions VALUES(9,'bangla','বাংলায় টি.এস. এলিয়েটের কবিতার প্রথম অনুবাদক-','রবীন্দ্রনাথ ঠাকুর','বিষ্ণু দে','সুধীন্দ্রনাথ দত্ত','বুদ্ধদেব বসু',0,NULL);
INSERT INTO questions VALUES(10,'bangla','''অগ্নিবীণা'' কাব্যগ্রন্থের সংকলিত প্রথম কবিতা-','অগ্নপথিক','বিদ্রোহী','প্রলয়োল্লাস','ধূমকেতু',2,NULL);
INSERT INTO questions VALUES(11,'bangla','''শেষের কবিতা'' রবীন্দ্রনাথ রচিত-','কবিতার নাম','গল্প সংকলনের নাম','উপন্যাসের নাম','কাব্য সংকলনের নাম',2,NULL);
INSERT INTO questions VALUES(12,'bangla','''আমার ভাইয়ের রক্তে রাঙানো ২১শে ফেব্রুয়ারি'' গানের রচয়িতা কে?','শামসুর রাহমান','আলতাফ মাহমুদ','হাসান হাফিজুর রহমান','আবদুল গাফ্ফার চৌধুরী',3,NULL);
INSERT INTO questions VALUES(13,'bangla','কোন দ্বিরুক্তি শব্দদ্বিত্ব বহুবচন সংকেত করে?','পাকা পাকা আম','ছি ছি কি করছ','নরম নরম হাত','উটু উটু মন',0,NULL);
INSERT INTO questions VALUES(14,'bangla','কোন প্রবচন বাক্য ব্যবহারিক দিক হতে সঠিক?','যত গর্জে তত বৃষ্টি হয় না','অধিক সন্ন্যাসীতে গাজন নষ্ট','নাচতে না জানলে উঠোন ভাঙ্গা','যেখানে বাঘের ভয় সেখানে বিপদ হয়',1,NULL);
INSERT INTO questions VALUES(15,'bangla','কোন বাক্যে ''মাথা'' শব্দটি বুদ্ধি অর্থে ব্যবহৃত?','তিনিই সমাজের মাথা','মাথা খাটিয়ে কাজ করবে','লজ্জায় আমার মাথা কাটা গেল','মাথা নেই তার মাথা ব্যথা',1,NULL);
INSERT INTO questions VALUES(16,'bangla','কোন শব্দে বিদেশি উপসর্গ ব্যবহৃত হয়েছে?','নিখুঁত','আনমনা','অবহেলা','নিমরাজি',3,NULL);
INSERT INTO questions VALUES(17,'bangla','কোনটি তদ্ভব শব্দ?','চাঁদ','সূর্য','নক্ষত্র','গগন',0,NULL);
INSERT INTO questions VALUES(18,'bangla','''উভয়কূল রক্ষা'' অর্থে ব্যবহৃত প্রবচন কোনটি?','কারো পৌষ মাস, কারও সর্বনাশ','চাল না চুলো, ঢেঁকী না কুলো','সাপও মরে, লাঠিও না ভাঙ্গে','বোঝার উপর, শাকের আঁটি',2,NULL);

-- ── ENGLISH (19-34) ─────────────────────────────────────────
INSERT INTO questions VALUES(19,'english','Choose the correct alternative to complete the sentence: ''He ____ to see us if he had been able to''','would come','would have come','may have come','may come',1,NULL);
INSERT INTO questions VALUES(20,'english','Choose the appropriate alternative to complete the sentence: ''He had a .... of fever.''','strong attack','severe attack','serious kind','bad attack',1,NULL);
INSERT INTO questions VALUES(21,'english','Choose the correct sentence.','I asked Javed had he passed','I asked Javed if he had passed','I asked Javed if you had passed','I asked Javed that had he passed',1,NULL);
INSERT INTO questions VALUES(22,'english','Choose the correct sentence (each/every/all).','A few of the three boys got a prize','Each of the three boys got a prize','Every of the three boys got a prize','All of the three boys got a prize',1,NULL);
INSERT INTO questions VALUES(23,'english','Choose the correct sentence (relative pronoun).','The man said that was a fool','The man who said that was a fool','The man that said that was a fool','The man which said that was a fool',1,NULL);
INSERT INTO questions VALUES(24,'english','Choose the correct answer. How long did you wait?','Till lunch time','Till he came','Until six o''clock','Since this morning',1,NULL);
INSERT INTO questions VALUES(25,'english','What will be the correct preposition? ''I am not bad ... tennis''.','in','at','about','with',1,NULL);
INSERT INTO questions VALUES(26,'english','What is the antonym of ''gentle''?','Harsh','modest','clever','rude',0,'ক ও ঘ উভয়ই সঠিক');
INSERT INTO questions VALUES(27,'english','What is the synonym of ''Jovial''?','Jolly','Gay','Jealous','Happy',0,'ক ও খ উভয়ই সঠিক');
INSERT INTO questions VALUES(28,'english','What is the synonym of ''Competent''?','Circumstance','Discrete','Capable','Prudent',2,NULL);
INSERT INTO questions VALUES(29,'english','Who is the author of ''A Farewell to Arms''?','H. G. Wells','George Orwell','Thomas More','Ernest Hemingway',3,NULL);
INSERT INTO questions VALUES(30,'english','Who is the author of ''Animal Farm''?','Thomas More','George Orwell','Boris Pasternak','Charles Dickens',1,NULL);
INSERT INTO questions VALUES(31,'english','Who is the author of ''India Wins Freedom''?','Mahatma Gandhi','J. L. Nehru','Abul Kalam Azad','Moulana Akram Khan',2,NULL);
INSERT INTO questions VALUES(32,'english','What kind of noun is ''Cattle''?','Proper','Common','Collective','Material',2,NULL);
INSERT INTO questions VALUES(33,'english','What kind of noun is ''Girl''?','Proper','Common','Collective','Material',1,NULL);
INSERT INTO questions VALUES(34,'english','What is the meaning of ''White Elephant''?','An elephant of white colour','A very costly or troublesome possession','A black marketer','A hoarder',1,NULL);

-- ── BANGLADESH (35-54) ──────────────────────────────────────
INSERT INTO questions VALUES(35,'bangladesh','বাংলাদেশ গণপ্রজাতন্ত্রের ঘোষণা হয়েছিল-','১৭ এপ্রিল, ১৯৭১','২৬ মার্চ, ১৯৭১','১১ এপ্রিল, ১৯৭১','১০ এপ্রিল, ১৯৭১',3,NULL);
INSERT INTO questions VALUES(36,'bangladesh','গণপ্রজাতন্ত্রী বাংলাদেশের সংবিধান প্রবর্তিত হয়-','২৫ মার্চ, ১৯৭১','২৫ মার্চ, ১৯৭২','১৬ ডিসেম্বর, ১৯৭১','১৬ ডিসেম্বর, ১৯৭২',3,NULL);
INSERT INTO questions VALUES(37,'bangladesh','বিখ্যাত সাধক শাহ সুলতান বলখীর মাজার কোথায়?','মহাস্থানগড়ে','শাহজাদপুরে','নেত্রকোনায়','রামপালে',0,NULL);
INSERT INTO questions VALUES(38,'bangladesh','বাংলাদেশের লোকশিল্প জাদুঘর কোথায়?','চট্টগ্রাম','বগুড়ায়','সোনারগাঁওয়ে','রামপালে',2,NULL);
INSERT INTO questions VALUES(39,'bangladesh','বাংলায় ইউরোপীয় বণিকদের মধ্যে বাণিজ্যের উদ্দেশ্যে প্রথম এসেছিলেন-','ইংরেজরা','ওলন্দাজরা','ফরাসিরা','পর্তুগিজরা',3,NULL);
INSERT INTO questions VALUES(40,'bangladesh','বাংলা নববর্ষ পহেলা বৈশাখ চালু করেছিলেন কে?','সম্রাট আকবর','শেরশাহ','লক্ষ্মণ সেন','বাদশাহ শাজাহান',0,NULL);
INSERT INTO questions VALUES(41,'bangladesh','পাহাড়পুরের বৌদ্ধ বিহারটি কি নামে পরিচিত ছিল?','সোমপুর বিহার','ধর্মপাল বিহার','জগদ্দল বিহার','শ্রী বিহার',0,NULL);
INSERT INTO questions VALUES(42,'bangladesh','বাংলাদেশে চীনামাটির সন্ধান পাওয়া গেছে-','বিজয়পুরে','রানীগঞ্জে','টেকেরহাটে','বিয়ানী বাজারে',0,NULL);
INSERT INTO questions VALUES(43,'bangladesh','ঢাকা বিশ্ববিদ্যালয় প্রতিষ্ঠিত হয় কোন সালে?','১৯০৫','১৯১১','১৯৩৫','১৯২১',3,NULL);
INSERT INTO questions VALUES(44,'bangladesh','ঢাকার বিখ্যাত তারা মসজিদ তৈরি করেন?','শায়েস্তা খান','নওয়াব সলিমুল্লাহ','মির্জা আহমেদ জান','খান সাহেব আবুল হাসানাত',2,NULL);
INSERT INTO questions VALUES(45,'bangladesh','পাখি ছাড়া ''বলাকা'' ও ''দোয়েল'' কিসের নাম?','দুটি কৃষি যন্ত্রপাতির নাম','দুটি কৃষি সংস্থার নাম','উন্নত জাতের গম শস্য','কৃষি খামারের নাম',2,NULL);
INSERT INTO questions VALUES(46,'bangladesh','''আপেল্বর'', ''কানাইবাঁসী'', ''মোহনবাঁসী'' ও ''বীটজবা'' কি জাতীয় ফলের নাম?','পেয়ারা','কলা','পেঁপে','জামরুল',1,NULL);
INSERT INTO questions VALUES(47,'bangladesh','বাংলায় চিরস্থায়ী বন্দোবস্ত প্রবর্তন করা হয় কোন সালে?','১৭০০ সালে','১৭৬২ সালে','১৯৯৫ সালে','১৭৯৩ সালে',3,NULL);
INSERT INTO questions VALUES(48,'bangladesh','কোন মুঘল সম্রাট বাংলার নাম দেন ''জান্নাতাবাদ''?','বাবর','হুমায়ুন','আকবর','জাহাঙ্গীর',1,NULL);
INSERT INTO questions VALUES(49,'bangladesh','উপমহাদেশের মধ্যে ঢাকা বিশ্ববিদ্যালয়ের প্রথম ভাইস চ্যান্সেলর-','ড. রমেশচন্দ্র মজুমদার','ড. সৈয়দ মোয়াজ্জেম হোসেন','ড. মাহমুদ হাসান','স্যার এ. এফ. রহমান',3,NULL);
INSERT INTO questions VALUES(50,'bangladesh','১৯৮৮ সালের সিউল অলিম্পিকে বাংলাদেশের কোন ভাস্করের শিল্পকর্ম প্রদর্শনীতে স্থান পায়?','শামীম শিকদার','সৈয়দ আব্দুল্লাহ খালেদ','হামিদুজ্জামান খান','আবদুস সুলতান',2,NULL);
INSERT INTO questions VALUES(51,'bangladesh','ঢাকা কখন সর্বপ্রথম বাংলার রাজধানী হয়েছে?','১২৫৫','১৬১০','১৯০৫','১৯৪৭',1,NULL);
INSERT INTO questions VALUES(52,'bangladesh','পূর্বাশা দ্বীপের অপর নাম-','নিঝুম দ্বীপ','সেন্ট মার্টিন','দক্ষিণ তালপট্টি','কুতুবদিয়া',2,NULL);
INSERT INTO questions VALUES(53,'bangladesh','''সার্ক''-এর প্রথম শীর্ষ বৈঠক অনুষ্ঠিত হয়-','১৯৮৪','১৯৮৭','১৯৮৫','১৯৮৬',2,NULL);
INSERT INTO questions VALUES(54,'bangladesh','আরব রাষ্ট্রগুলোর মধ্যে কোনটি বাংলাদেশকে প্রথম স্বীকৃতি দেয়?','ইরাক','আলজেরিয়া','সৌদি আরব','জর্ডান',0,NULL);

-- ── INTERNATIONAL (55-68) ───────────────────────────────────
INSERT INTO questions VALUES(55,'international','''পিএলও''-এর সদর দপ্তর-','তিউনিস','রামাল্লা','বেনগাজি','মরক্কো',1,NULL);
INSERT INTO questions VALUES(56,'international','জাতিসংঘের প্রথম মহাসচিব ছিলেন-','উ থান্ট','ট্রিগভেলি','দাগ হ্যামারশোল্ড','কুর্ট ওয়াল্ডহেইম',1,NULL);
INSERT INTO questions VALUES(57,'international','নিরাপত্তা পরিষদের এশীয় আসনে বাংলাদেশের প্রতিদ্বন্দ্বী ছিল-','ফিলিপাইন','জাপান','ইন্দোনেশিয়া','থাইল্যান্ড',1,NULL);
INSERT INTO questions VALUES(58,'international','সাধারণ পরিষদের নিয়মিত অধিবেশন শুরু হয়-','সেপ্টেম্বর মাসের তৃতীয় মঙ্গলবার','সেপ্টেম্বর মাসের প্রথম সোমবার','সেপ্টেম্বর মাসের দ্বিতীয় মঙ্গলবার','সেপ্টেম্বর মাসের চতুর্থ মঙ্গলবার',0,NULL);
INSERT INTO questions VALUES(59,'international','জাতিসংঘের বর্তমান সদস্য সংখ্যা কত?','১৫৬','১৫৭','১৫৮','১৯৩',3,NULL);
INSERT INTO questions VALUES(60,'international','ইসলামি সম্মেলন সংস্থার সচিবালয় কোথায়?','তেহরান','জেদ্দা','কায়রো','রিয়াদ',1,NULL);
INSERT INTO questions VALUES(61,'international','যে দেশ ''এসডিআই'' প্রতিরক্ষা কর্মসূচি গ্রহণ করেছে-','ব্রিটেন','ফ্রান্স','যুক্তরাষ্ট্র','রাশিয়া',2,NULL);
INSERT INTO questions VALUES(62,'international','ব্রিটেনের প্রশাসনিক সদর দপ্তরকে বলা হয়-','ওয়েস্টমিনস্টার অ্যাবে','হোয়াইট হল','মার্বেল চার্চ','বুশ হাউজ',1,NULL);
INSERT INTO questions VALUES(63,'international','দ্বিতীয় মহাযুদ্ধে জার্মানি আত্মসমর্পণ করে-','১৯৪২ সালের নভেম্বর মাসে','১৯৪৩ সালের ফেব্রুয়ারি মাসে','১৯৪৫ সালের মে মাসে','১৯৪৫ সালের সেপ্টেম্বর মাসে',2,NULL);
INSERT INTO questions VALUES(64,'international','কঙ্গোকে বিদেশি শাসন থেকে মুক্ত করার লড়াইয়ে চিরস্মরণীয় নাম-','কাশাভুবু','প্যাট্রিক লুমুম্বা','শোম্বে','মবুতু',1,NULL);
INSERT INTO questions VALUES(65,'international','হিরোশিমায় এটম বোমা ফেলা হয়েছিল-','১৯৪৫ সালের আগস্ট মাসে','১৯৪৫ সালের মে মাসে','১৯৪৪ সালের সেপ্টেম্বর মাসে','১৯৪৪ সালের আগস্ট মাসে',0,NULL);
INSERT INTO questions VALUES(66,'international','''আইএমএফ''-এর সদর দপ্তর কোথায়?','ওয়াশিংটন','মস্কো','লন্ডন','নিউইয়র্ক',0,NULL);
INSERT INTO questions VALUES(67,'international','নিকারাগুয়ার যে বিদ্রোহীরা যুক্তরাষ্ট্র সমর্থনপুষ্ট তার নাম-','ইউনিটা','সান্ডিনিস্তা','কন্ট্রা','সোয়াপো',2,NULL);
INSERT INTO questions VALUES(68,'international','''ব্যাবিলনের ঝুলন্ত উদ্যান'' কোন দেশে অবস্থিত?','ইরান','ইরাক','মিশর','সিরিয়া',1,NULL);

-- ── SCIENCE (69-84) ─────────────────────────────────────────
INSERT INTO questions VALUES(69,'science','ইতিহাস বিখ্যাত ট্রয় নগরী কোথায়?','গ্রীসে','ইটালিতে','তুরস্কে','স্পেনে',2,NULL);
INSERT INTO questions VALUES(70,'science','নবায়নযোগ্য শক্তি উৎসের একটি উদাহরণ হলো-','পারমাণবিক জ্বালানি','পিট কয়লা','ফুয়েল সেল','সূর্য',3,NULL);
INSERT INTO questions VALUES(71,'science','প্রেসার কুকারে রান্না তাড়াতাড়ি হয়, কারণ-','রান্নার জন্য শুধু তাপ নয় চাপও কাজে লাগে','বদ্ধ পাত্রে তাপ সংরক্ষিত হয়','উচ্চ চাপে তরলের স্ফুটনাঙ্ক বৃদ্ধি পায়','সঞ্চিত বাষ্পের তাপ রান্নার সহায়ক',2,NULL);
INSERT INTO questions VALUES(72,'science','যে তিনটি মৌলিক বর্ণের সমন্বয়ে অন্যান্য বর্ণ সৃষ্টি করা যায়-','লাল, হলুদ, নীল','লাল, কমলা, বেগুনি','হলুদ, সবুজ, নীল','লাল, নীল, সবুজ',3,NULL);
INSERT INTO questions VALUES(73,'science','ভৌগোলিকভাবে গুরুত্বপূর্ণ একটি কাল্পনিক রেখা বাংলাদেশের উপর দিয়ে গিয়েছে, সেটি হচ্ছে-','মূল মধ্যরেখা','কর্কটক্রান্তি রেখা','মকরক্রান্তি রেখা','আন্তর্জাতিক তারিখ রেখা',1,NULL);
INSERT INTO questions VALUES(74,'science','মাছ অক্সিজেন নেয়-','মাঝে মাঝে পানির উপর নাক তুলে','পানিতে অক্সিজেন ও হাইড্রোজেন বিশ্লিষ্ট করে','পটকার মধ্যে জমানো বাতাস হতে','পানির মধ্যে দ্রবীভূত বাতাস হতে',3,NULL);
INSERT INTO questions VALUES(75,'science','কচুশাক বিশেষভাবে মূল্যবান যে উপাদানের জন্য তা হলো-','ভিটামিন এ','ভিটামিন সি','লৌহ','ক্যালসিয়াম',2,NULL);
INSERT INTO questions VALUES(76,'science','সাধারণ ড্রাইসেলে ইলেকট্রোড হিসেবে থাকে-','তামার দণ্ড ও দস্তার দণ্ড','তামার পাতে ও দস্তার পাতে','কার্বন দণ্ড ও দস্তার কোটা','তামার দণ্ড ও দস্তার কোটা',2,NULL);
INSERT INTO questions VALUES(77,'science','দূরের বিদ্যুৎ উৎপাদন কেন্দ্র হতে বিদ্যুৎ আনতে হাইভোল্টেজ ব্যবহারের কারণ-','এতে বিদ্যুতের অপচয় কম হয়','পথে কমে গিয়েও প্রয়োজনীয় ভোল্টেজ বজায় থাকে','অধিক বিদ্যুৎ প্রবাহ পাওয়া যায়','প্রয়োজনমত ভোল্টেজ কমিয়ে ব্যবহার করা যায়',0,NULL);
INSERT INTO questions VALUES(78,'science','সংকর ধাতু পিতলের উপাদান হলো-','তামা ও টিন','তামা ও দস্তা','তামা ও নিকেল','তামা ও সীসা',1,NULL);
INSERT INTO questions VALUES(79,'science','আমাদের দেহকোষ রক্ত হতে গ্রহণ করে-','অক্সিজেন ও গ্লুকোজ','অক্সিজেন ও রক্তের আমিষ','ইউরিয়া ও গ্লুকোজ','এমাইনো এসিড ও কার্বন ডাই অক্সাইড',0,NULL);
INSERT INTO questions VALUES(80,'science','পৃথিবীর ঘূর্ণনের ফলে আমরা ছিটকে পড়ি না-','মহাকর্ষ বলের জন্য','মধ্যাকর্ষণ বলের জন্য','আমরা স্থির থাকার জন্য','পৃথিবীর সঙ্গে আমাদের আবর্তনের জন্য',1,NULL);
INSERT INTO questions VALUES(81,'science','নিচের কোনটি জীবাশ্ম জ্বালানি নয়?','পেট্রোলিয়াম','কয়লা','প্রাকৃতিক গ্যাস','বায়োগ্যাস',3,NULL);
INSERT INTO questions VALUES(82,'science','বৈদ্যুতিক মটর এমন একটি যন্ত্রকৌশল যা-','তাপ শক্তিকে যান্ত্রিক শক্তিতে রূপান্তরিত করে','তাপ শক্তিকে তড়িৎ শক্তিতে রূপান্তরিত করে','যান্ত্রিক শক্তিকে তড়িৎ শক্তিতে রূপান্তরিত করে','তড়িৎ শক্তিকে যান্ত্রিক শক্তিতে রূপান্তরিত করে',3,NULL);
INSERT INTO questions VALUES(83,'science','যে বায়ু সর্বদাই উচ্চচাপ অঞ্চল থেকে নিম্নচাপ অঞ্চলের দিকে প্রবাহিত হয় তাকে বলা হয়-','অয়ন বায়ু','প্রত্যয়ন বায়ু','মৌসুমী বায়ু','নিয়ত বায়ু',3,NULL);
INSERT INTO questions VALUES(84,'science','জলজ উদ্ভিদ সহজে ভাসতে পারে, কারণ-','এরা অনেক ছোট হয়','এদের কাণ্ডে অনেক বায়ু কুঠুরী থাকে','এরা পানিতে জন্মে','এদের পাতা অনেক কম থাকে',1,NULL);

-- ── MATH (85-100) ───────────────────────────────────────────
INSERT INTO questions VALUES(85,'math','১ থেকে ৩০ পর্যন্ত কয়টি মৌলিক সংখ্যা আছে?','১১টি','৮টি','১০টি','৯টি',2,NULL);
INSERT INTO questions VALUES(86,'math','নিচের কোন সংখ্যাটি মৌলিক সংখ্যা?','১৪৩','৯১','৪৭','৮৭',2,NULL);
INSERT INTO questions VALUES(87,'math','দুটি সংখ্যার গুণফল ১৫৩৬। সংখ্যা দুটির ল.সা.গু ৯৬ হলে, গ.সা.গু কত?','১৬','২৪','৩২','১২',0,NULL);
INSERT INTO questions VALUES(88,'math','(১×০.১×০.০১) / (২×০.২×০.০০২) এর মান কত?','১/৮০','১/৮০০','১/৮০০০','১/৮',3,NULL);
INSERT INTO questions VALUES(89,'math','চিনির মূল্য ২৫% বৃদ্ধি পাওয়াতে একটি পরিবার চিনি খাওয়া কমাল যাতে ব্যয় বৃদ্ধি না পায়। শতকরা কত কমিয়েছিল?','৩০%','২৫%','১৫%','২০%',3,NULL);
INSERT INTO questions VALUES(90,'math','টাকায় তিনটি করে আম কিনে টাকায় দুইটি আম বিক্রয় করলে শতকরা কত লাভ হবে?','৫০%','৩০%','৩৩%','৩১%',0,NULL);
INSERT INTO questions VALUES(91,'math','সরল সুদের হার শতকরা কত টাকা হলে যে কোন মূলধন ৮ বছরের সুদে-আসলে তিনগুণ হবে?','১২.৫০ টাকা','২০ টাকা','২৫ টাকা','১৫ টাকা',2,NULL);
INSERT INTO questions VALUES(92,'math','৬০ লিটার কেরোসিন ও পেট্রোলের মিশ্রণের অনুপাত ৭:৩। আর কত লিটার পেট্রোল মিশালে অনুপাত ৩:৭ হবে?','৭০','৮০','৯০','৯৮',1,NULL);
INSERT INTO questions VALUES(93,'math','১ থেকে ৪৯ পর্যন্ত সংখ্যাগুলোর গড় কত?','২৩','২৪.৫','২৫','২৫.৫',2,NULL);
INSERT INTO questions VALUES(94,'math','a + b = 5 এবং a - b = 3 হলে, ab এর মান কত?','2','3','4','5',2,NULL);
INSERT INTO questions VALUES(95,'math','যদি (x - 5)(a + x) = x² - 25 হয় তবে, a এর মান কত?','-5','5','25','-25',1,NULL);
INSERT INTO questions VALUES(96,'math','ত্রিভুজ ABC এর BE = EF = CF। ABFC এর ক্ষেত্রফল ৪৮ বর্গফুট হলে, △AEF এর ক্ষেত্রফল কত বর্গফুট?','৭২','৬০','৪৮','৬৪',0,NULL);
INSERT INTO questions VALUES(97,'math','ত্রিভুজের একটি কোণ উহার অপর দুটি কোণের সমষ্টির সমান হলে ত্রিভুজটি-','সমকোণী','স্থূলকোণী','সমবাহু','সূক্ষ্মকোণী',0,NULL);
INSERT INTO questions VALUES(98,'math','সমবাহু ত্রিভুজের বাহুর দৈর্ঘ্য যদি a হয়, তবে ক্ষেত্রফল হবে-','√৩/৪ × a²','√৩/২ × a²','৩/২ × a²','১/২ × a²',0,NULL);
INSERT INTO questions VALUES(99,'math','নির্মাতা ২০% লাভে ও খুচরা বিক্রেতা ২০% লাভে বিক্রয় করে। নির্মাণ খরচ ১০০ টাকা হলে খুচরা মূল্য কত?','১৮০ টাকা','১২০ টাকা','১৪৪ টাকা','১২৮ টাকা',2,NULL);
INSERT INTO questions VALUES(100,'math','a + b + c = 0 হলে, a³ + b³ + c³ এর মান কত?','abc','3abc','6abc','9abc',1,NULL);
