-- Fictional sample data for the Preach My Gospel database schema.
-- Run this after creating the tables in the preach_my_gospel database.
-- IDs are explicit so the relationships are easy to inspect.

SET NAMES utf8mb4;
START TRANSACTION;

INSERT INTO ward (ward_id, name) VALUES
    (1, 'Cedar Ward'),
    (2, 'Maple Ward');

INSERT INTO area (area_id, name) VALUES
    (1, 'North Area'),
    (2, 'South Area');

INSERT INTO area_ward (area_id, ward_id) VALUES
    (1, 1),
    (1, 2),
    (2, 2);

INSERT INTO spoken_language (language_id, name) VALUES
    (1, 'English'),
    (2, 'Spanish');

INSERT INTO address (address_id, ward_id, street, city, state, postal_code) VALUES
    (1, 1, '100 Cedar Street', 'Exampleville', 'CO', '80000'),
    (2, 2, '200 Maple Avenue', 'Exampleville', 'CO', '80001'),
    (3, 1, '300 Pine Road', 'Exampleville', 'CO', '80002');

INSERT INTO person
    (person_id, address_id, language_id, first_name, last_name, phone, date_of_birth, gender)
VALUES
    (1, 1, 1, 'Mia', 'Chen', '555-0101', '2002-04-12', 'Female'),
    (2, 1, 1, 'Evan', 'Chen', '555-0102', '2005-09-23', 'Male'),
    (3, 2, 2, 'Leo', 'Martinez', '555-0103', '1998-01-17', 'Male'),
    (4, 3, 1, 'Nora', 'Patel', '555-0104', '1989-06-08', 'Female'),
    (5, 2, 2, 'Jonah', 'Reed', '555-0105', '1993-11-02', 'Male');

INSERT INTO friend_profile
    (person_id, area_id, teaching_started_on, current_status, status_changed_on, how_found, background)
VALUES
    (1, 1, '2026-08-15', 'actively_teaching', '2026-08-15', 'Member referral', 'Interested in learning about prayer and family history.'),
    (2, 1, '2026-09-10', 'investigating', '2026-09-10', 'Family connection', 'Usually attends lessons with a sibling.'),
    (3, 2, '2026-05-05', 'baptized', '2026-08-15', 'Community event', 'Completed the lessons and was baptized in August.');

INSERT INTO member_profile (person_id) VALUES
    (4),
    (5);

INSERT INTO person_relationship
    (person_id, related_person_id, relationship_type)
VALUES
    (1, 2, 'sibling');

INSERT INTO zone (zone_id, name) VALUES
    (1, 'North Zone'),
    (2, 'South Zone');

INSERT INTO missionary (missionary_id, name) VALUES
    (1, 'Alex Rivera'),
    (2, 'Taylor Brooks'),
    (3, 'Jordan Kim'),
    (4, 'Casey Morgan');

INSERT INTO companionship (companionship_id, name) VALUES
    (1, 'North Companionship'),
    (2, 'South Companionship');

INSERT INTO companionship_member (companionship_id, missionary_id) VALUES
    (1, 1),
    (1, 2),
    (2, 3),
    (2, 4);

INSERT INTO companionship_assignment (companionship_id, area_id, zone_id) VALUES
    (1, 1, 1),
    (2, 2, 2);

INSERT INTO lesson_catalog
    (lesson_id, name, is_custom, required_for_baptism)
VALUES
    (1, 'Lesson 1: The Restoration', FALSE, TRUE),
    (2, 'Lesson 2: The Plan of Salvation', FALSE, TRUE),
    (3, 'Lesson 3: The Gospel of Jesus Christ', FALSE, TRUE),
    (4, 'Family Prayer Follow-up', TRUE, FALSE);

INSERT INTO principle_catalog (principle_id, name, is_custom) VALUES
    (1, 'Faith in Jesus Christ', FALSE),
    (2, 'Repentance', FALSE),
    (3, 'Prayer', FALSE),
    (4, 'Family scripture study', TRUE);

INSERT INTO commitment_catalog
    (commitment_id, name, is_custom, required_for_baptism)
VALUES
    (1, 'Attend church', FALSE, TRUE),
    (2, 'Pray daily', FALSE, TRUE),
    (3, 'Read the assigned scripture', FALSE, TRUE),
    (4, 'Meet a ward member', TRUE, FALSE);

-- Insert appointment 5 before appointment 4 because appointment 4 points to it.
INSERT INTO lesson_appointment
    (appointment_id, scheduled_at, status, rescheduled_to_appointment_id, notes)
VALUES
    (1, '2026-10-01 18:00:00', 'completed', NULL, 'Lesson with Mia and Evan.'),
    (2, '2026-10-04 11:00:00', 'canceled', NULL, 'Canceled by the family.'),
    (3, '2026-10-15 18:00:00', 'scheduled', NULL, 'Follow-up lesson.'),
    (5, '2026-10-14 19:00:00', 'scheduled', NULL, 'New time after rescheduling.'),
    (4, '2026-10-05 18:00:00', 'rescheduled', 5, 'Rescheduled to appointment 5.');

INSERT INTO appointment_friend (appointment_id, friend_id) VALUES
    (1, 1),
    (1, 2),
    (2, 1),
    (3, 1),
    (4, 3),
    (5, 3);

INSERT INTO appointment_member (appointment_id, member_id) VALUES
    (1, 4),
    (3, 5),
    (5, 5);

INSERT INTO interaction
    (interaction_id, occurred_at, interaction_type, notes)
VALUES
    (1, '2026-10-01 18:00:00', 'lesson', 'Group lesson at the Chen home.'),
    (2, '2026-10-02 17:30:00', 'phone_call', 'Checked in with Mia.'),
    (3, '2026-10-08 19:00:00', 'member_visit', 'Nora joined a follow-up visit.'),
    (4, '2026-09-29 18:00:00', 'lesson', 'Lesson with Leo.');

INSERT INTO interaction_friend (interaction_id, friend_id) VALUES
    (1, 1),
    (1, 2),
    (2, 1),
    (3, 2),
    (4, 3);

INSERT INTO interaction_member (interaction_id, member_id) VALUES
    (1, 4),
    (2, 5),
    (3, 4),
    (4, 5);

INSERT INTO lesson_session
    (session_id, appointment_id, interaction_id, actual_at, review_description, notes)
VALUES
    (1, 1, 1, '2026-10-01 18:00:00', 'Discussed the Restoration and answered questions.', 'Mia and Evan attended.'),
    (2, NULL, 4, '2026-09-29 18:00:00', 'Reviewed the plan of salvation and baptism preparation.', 'Leo attended with Jonah.');

INSERT INTO session_friend (session_id, friend_id) VALUES
    (1, 1),
    (1, 2),
    (2, 3);

INSERT INTO session_member (session_id, member_id) VALUES
    (1, 4),
    (2, 5);

INSERT INTO session_lesson (session_id, lesson_id) VALUES
    (1, 1),
    (2, 1),
    (2, 2),
    (2, 3);

INSERT INTO session_principle (session_id, principle_id) VALUES
    (1, 1),
    (1, 3),
    (2, 1),
    (2, 2);

INSERT INTO friend_lesson_completion
    (friend_id, lesson_id, session_id, completed_on)
VALUES
    (1, 1, 1, '2026-10-01'),
    (2, 1, 1, '2026-10-01'),
    (3, 1, 2, '2026-09-29'),
    (3, 2, 2, '2026-09-29'),
    (3, 3, 2, '2026-09-29');

INSERT INTO friend_commitment
    (commitment_instance_id, friend_id, commitment_id, session_id, extended_on, due_on, status, kept_on)
VALUES
    (1, 1, 3, 1, '2026-10-01', '2026-10-05', 'kept', '2026-10-04'),
    (2, 2, 1, 1, '2026-10-01', '2026-10-06', 'pending', NULL),
    (3, 3, 2, 2, '2026-09-29', '2026-10-03', 'kept', '2026-10-02'),
    (4, 3, 1, 2, '2026-09-29', '2026-10-04', 'kept', '2026-10-04');

INSERT INTO referral
    (referral_id, referred_friend_id, referring_member_id, referred_on, notes)
VALUES
    (1, 1, 4, '2026-08-12', 'Nora introduced Mia to the missionaries.'),
    (2, 3, 5, '2026-05-01', 'Jonah invited Leo to a community activity.');

INSERT INTO friend_baptism
    (friend_id, date_set, scheduled_date, ordinance_completed_on, area_id)
VALUES
    (1, '2026-10-02', '2026-11-07', NULL, NULL),
    (3, '2026-07-20', '2026-08-15', '2026-08-15', 2);

COMMIT;
