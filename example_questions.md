# Example Questions

These questions were run against the sample data in [db_data.sql](db_data.sql) with zero-shot prompting. For each one, **Expected** is the correct answer worked out by hand from the sample data.

## 1. Which friends have completed all lessons required for baptism?
**Expected:** Leo Martinez (completed Lessons 1–3).

**Gemini SQL:**
```sql
SELECT T1.person_id, T1.first_name, T1.last_name
FROM person AS T1
JOIN friend_profile AS T2 ON T1.person_id = T2.person_id
WHERE NOT EXISTS (
    SELECT T3.lesson_id 
    FROM lesson_catalog AS T3 
    WHERE T3.required_for_baptism = 1 
    AND T3.lesson_id NOT IN (
        SELECT T4.lesson_id 
        FROM friend_lesson_completion AS T4 
        WHERE T4.friend_id = T1.person_id
    )
);
```
**Friendly Response:** "The result means that there is one friend, Leo Martinez (with a person ID of 3), who has completed all the lessons required for baptism."
**Correct?** This is correct.

## 2. Who is Mia Chen's sibling, and have they attended a lesson together?
**Expected:** Evan Chen. They both attended the 2026-10-01 lesson (session 1).

**Gemini SQL:**
```sql
SELECT 
    p_sibling.first_name, 
    p_sibling.last_name,
    CASE 
        WHEN EXISTS (
            SELECT 1 
            FROM session_friend sf1
            JOIN session_friend sf2 ON sf1.session_id = sf2.session_id
            WHERE sf1.friend_id = p_mia.person_id 
              AND sf2.friend_id = p_sibling.person_id
        ) THEN 'Yes'
        ELSE 'No'
    END AS attended_lesson_together
FROM person p_mia
JOIN person_relationship pr ON p_mia.person_id = pr.person_id
JOIN person p_sibling ON pr.related_person_id = p_sibling.person_id
WHERE p_mia.first_name = 'Mia' 
  AND p_mia.last_name = 'Chen'
  AND pr.relationship_type = 'Sibling';
```
**Friendly Response:** "Mia Chen's sibling is Evan Chen, and they have attended a lesson together."
**Correct?** Mostly correct. It didn't specify what lesson they attended together, but that could be fixed by the question's wording.

## 3. Which ward member referred the most friends?
**Expected:** A tie. Nora Patel referred Mia and Jonah Reed referred Leo, so each has 1 referral.

**Gemini SQL:**
```sql
SELECT p.first_name, p.last_name, COUNT(r.referral_id) AS referral_count
FROM member_profile mp
JOIN person p ON mp.person_id = p.person_id
JOIN referral r ON mp.person_id = r.referring_member_id
GROUP BY mp.person_id
ORDER BY referral_count DESC
LIMIT 1;
```
**Friendly Response:** "Nora Patel is the ward member who has referred the most friends, with a total of 1 referral."
**Correct?** No, in this case there was a tie and AI should have returned both members, but in the SELECT query it had a limit of 1 person. 

## 4. What upcoming appointments are scheduled, and which friends are in them?
**Expected:** Appointment 5 on 2026-10-14 with Leo (the rescheduled one), and appointment 3 on 2026-10-15 with Mia.

**Gemini SQL:**
```sql
SELECT 
    la.appointment_id, 
    la.scheduled_at, 
    la.status, 
    p.first_name, 
    p.last_name
FROM lesson_appointment la
JOIN appointment_friend af ON la.appointment_id = af.appointment_id
JOIN person p ON af.friend_id = p.person_id
WHERE la.scheduled_at >= NOW()
ORDER BY la.scheduled_at ASC;
```
**Friendly Response:** 
"*   **Leo Martinez** has an appointment (ID: 5) scheduled for October 14, 2026, at 7:00 PM.
*   **Mia Chen** has an appointment (ID: 3) scheduled for October 15, 2026, at 6:00 PM."
**Correct?** Mostly, it got the right appointments and people, but we would have liked it to say the "fifth appointment" or "third appointment" instead of listing the IDs of the appointments. 

## 5. Which commitments are still pending?
**Expected:** Evan Chen: "Attend church", due 2026-10-06.

**Gemini SQL:**
```sql
SELECT 
    fc.commitment_instance_id, 
    p.first_name, 
    p.last_name, 
    cc.name AS commitment_name, 
    fc.due_on
FROM friend_commitment fc
JOIN person p ON fc.friend_id = p.person_id
JOIN commitment_catalog cc ON fc.commitment_id = cc.commitment_id
WHERE fc.status = 'pending';
```
**Friendly Response:** "There is one pending commitment: Evan Chen has a commitment to 'Attend church' which was due on October 6, 2026."
**Correct?** This is correct. 

## 6. Which missionaries are teaching in the area where Mia lives?
**Expected:** Mia's friend profile is in North Area, which is served by the North Companionship: Alex Rivera and Taylor Brooks.

**Gemini SQL:**
```sql
SELECT DISTINCT m.name
FROM missionary m
JOIN companionship_member cm ON m.missionary_id = cm.missionary_id
JOIN companionship_assignment ca ON cm.companionship_id = ca.companionship_id
JOIN area a ON ca.area_id = a.area_id
JOIN friend_profile fp ON a.area_id = fp.area_id
JOIN person p ON fp.person_id = p.person_id
WHERE p.first_name = 'Mia';
```
**Friendly Response:** "The missionaries teaching in the area where Mia lives are Alex Rivera and Taylor Brooks."
**Correct?** Yes; it didn't specify which area that is, but that also wasn't specified in the question.

## 7. Who is actively progressing?
**Expected:** This depends on the current date, because it uses the business rule (lesson completed or commitment kept in the last 7 days). The latest activity in the data is a commitment kept on 2026-10-04, so if it's run after 2026-10-11 the answer is nobody.

**Gemini SQL:**
```sql
SELECT DISTINCT
    p.first_name,
    p.last_name
FROM friend_profile fp
JOIN person p ON fp.person_id = p.person_id
LEFT JOIN friend_lesson_completion flc ON fp.person_id = flc.friend_id
LEFT JOIN friend_commitment fc ON fp.person_id = fc.friend_id
WHERE (flc.completed_on >= CURRENT_DATE - INTERVAL 7 DAY)
   OR (fc.kept_on >= CURRENT_DATE - INTERVAL 7 DAY);
```
**Friendly Response:** "The result `[]` means that there are currently no friends who meet the criteria for 'actively progressing.' Specifically, there are no friends who have completed a lesson or kept a commitment within the last 7 days."
**Correct?** Yes

## 8. Which friends have a baptism date set but are not baptized yet?
**Expected:** Mia Chen, scheduled for 2026-11-07.

**Gemini SQL:**
```sql
SELECT
    p.first_name,
    p.last_name
FROM friend_baptism fb
JOIN person p ON fb.friend_id = p.person_id
WHERE fb.date_set IS NOT NULL
  AND fb.ordinance_completed_on IS NULL;
```
**Friendly Response:** "The result `[('Mia', 'Chen')]` means that Mia Chen is the only friend who has a baptism date set but has not yet completed the ordinance."
**Correct?** Mostly, it got Mia Chen correct, but it didn't list the date of the baptism. 
