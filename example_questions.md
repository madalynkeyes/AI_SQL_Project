# Example Questions

These questions were run against the sample data in [db_data.sql](db_data.sql) with zero-shot prompting. For each one, **Expected** is the correct answer worked out by hand from the sample data.

## 1. Which friends have completed all lessons required for baptism?
**Expected:** Leo Martinez (completed Lessons 1–3).

**Gemini SQL:**
```sql
-- TODO
```
**Friendly Response:** <!-- TODO -->
**Correct?** <!-- TODO -->

## 2. Who is Mia Chen's sibling, and have they attended a lesson together?
**Expected:** Evan Chen. They both attended the 2026-10-01 lesson (session 1).

**Gemini SQL:**
```sql
-- TODO
```
**Friendly Response:** <!-- TODO -->
**Correct?** <!-- TODO -->

## 3. Which ward member referred the most friends?
**Expected:** A tie. Nora Patel referred Mia and Jonah Reed referred Leo, so each has 1 referral.

**Gemini SQL:**
```sql
-- TODO
```
**Friendly Response:** <!-- TODO -->
**Correct?** <!-- TODO -->

## 4. What upcoming appointments are scheduled, and which friends are in them?
**Expected:** Appointment 5 on 2026-10-14 with Leo (the rescheduled one), and appointment 3 on 2026-10-15 with Mia.

**Gemini SQL:**
```sql
-- TODO
```
**Friendly Response:** <!-- TODO -->
**Correct?** <!-- TODO -->

## 5. Which commitments are still pending?
**Expected:** Evan Chen: "Attend church", due 2026-10-06.

**Gemini SQL:**
```sql
-- TODO
```
**Friendly Response:** <!-- TODO -->
**Correct?** <!-- TODO -->

## 6. Which missionaries are teaching in the area where Mia lives?
**Expected:** Mia's friend profile is in North Area, which is served by the North Companionship: Alex Rivera and Taylor Brooks.

**Gemini SQL:**
```sql
-- TODO
```
**Friendly Response:** <!-- TODO -->
**Correct?** <!-- TODO -->

## 7. Who is actively progressing?
**Expected:** This depends on the current date, because it uses the business rule (lesson completed or commitment kept in the last 7 days). The latest activity in the data is a commitment kept on 2026-10-04, so if it's run after 2026-10-11 the answer is nobody.

**Gemini SQL:**
```sql
-- TODO
```
**Friendly Response:** <!-- TODO -->
**Correct?** <!-- TODO -->

## 8. Which friends have a baptism date set but are not baptized yet?
**Expected:** Mia Chen, scheduled for 2026-11-07.

**Gemini SQL:**
```sql
-- TODO
```
**Friendly Response:** <!-- TODO -->
**Correct?** <!-- TODO -->
