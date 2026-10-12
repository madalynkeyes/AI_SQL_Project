CREATE TABLE IF NOT EXISTS ward (
    ward_id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(255) NOT NULL
);

CREATE TABLE IF NOT EXISTS area (
    area_id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(255) NOT NULL
) ENGINE = InnoDB;

CREATE TABLE IF NOT EXISTS area_ward (
    area_id INT NOT NULL,
    ward_id INT NOT NULL,
    PRIMARY KEY (area_id, ward_id),
    FOREIGN KEY (area_id) REFERENCES area(area_id),
    FOREIGN KEY (ward_id) REFERENCES ward(ward_id)
) ENGINE = InnoDB;

CREATE TABLE IF NOT EXISTS spoken_language (
    language_id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100) NOT NULL UNIQUE
) ENGINE = InnoDB;

-- Addresses can be shared by multiple people.
CREATE TABLE IF NOT EXISTS address (
    address_id INT AUTO_INCREMENT PRIMARY KEY,
    ward_id INT NOT NULL,
    street VARCHAR(255) NOT NULL,
    city VARCHAR(100),
    state VARCHAR(100),
    postal_code VARCHAR(30),
    FOREIGN KEY (ward_id) REFERENCES ward(ward_id)
) ENGINE = InnoDB;

-- Person is shared by friends and members.
CREATE TABLE IF NOT EXISTS person (
    person_id INT AUTO_INCREMENT PRIMARY KEY,
    address_id INT,
    language_id INT,
    first_name VARCHAR(100) NOT NULL,
    last_name VARCHAR(100) NOT NULL,
    phone VARCHAR(50),
    date_of_birth DATE,
    gender VARCHAR(50),
    FOREIGN KEY (address_id) REFERENCES address(address_id),
    FOREIGN KEY (language_id) REFERENCES spoken_language(language_id),
    INDEX idx_person_address (address_id)
) ENGINE = InnoDB;

CREATE TABLE IF NOT EXISTS friend_profile (
    person_id INT PRIMARY KEY,
    area_id INT,
    teaching_started_on DATE,
    current_status VARCHAR(30) NOT NULL DEFAULT 'investigating',
    status_changed_on DATE,
    how_found VARCHAR(255),
    background TEXT,
    FOREIGN KEY (person_id) REFERENCES person(person_id),
    FOREIGN KEY (area_id) REFERENCES area(area_id),
    CHECK (current_status IN (
        'investigating',
        'actively_teaching',
        'stopped_teaching',
        'lost_contact',
        'baptized'
    )),
    INDEX idx_friend_area (area_id),
    INDEX idx_friend_status (current_status)
) ENGINE = InnoDB;

CREATE TABLE IF NOT EXISTS member_profile (
    person_id INT PRIMARY KEY,
    FOREIGN KEY (person_id) REFERENCES person(person_id)
) ENGINE = InnoDB;

-- Store each family relationship once.
CREATE TABLE IF NOT EXISTS person_relationship (
    person_id INT NOT NULL,
    related_person_id INT NOT NULL,
    relationship_type VARCHAR(100) NOT NULL,
    PRIMARY KEY (person_id, related_person_id),
    FOREIGN KEY (person_id) REFERENCES person(person_id),
    FOREIGN KEY (related_person_id) REFERENCES person(person_id),
    CHECK (person_id <> related_person_id)
) ENGINE = InnoDB;

-- Missionaries and current companionship assignments.
CREATE TABLE IF NOT EXISTS zone (
    zone_id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(255) NOT NULL
) ENGINE = InnoDB;

CREATE TABLE IF NOT EXISTS missionary (
    missionary_id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(255) NOT NULL
) ENGINE = InnoDB;

CREATE TABLE IF NOT EXISTS companionship (
    companionship_id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(255)
) ENGINE = InnoDB;

CREATE TABLE IF NOT EXISTS companionship_member (
    companionship_id INT NOT NULL,
    missionary_id INT NOT NULL UNIQUE,
    PRIMARY KEY (companionship_id, missionary_id),
    FOREIGN KEY (companionship_id)
        REFERENCES companionship(companionship_id),
    FOREIGN KEY (missionary_id)
        REFERENCES missionary(missionary_id)
) ENGINE = InnoDB;

-- One current area and zone per companionship.
CREATE TABLE IF NOT EXISTS companionship_assignment (
    companionship_id INT PRIMARY KEY,
    area_id INT NOT NULL,
    zone_id INT NOT NULL,
    FOREIGN KEY (companionship_id)
        REFERENCES companionship(companionship_id),
    FOREIGN KEY (area_id) REFERENCES area(area_id),
    FOREIGN KEY (zone_id) REFERENCES zone(zone_id)
) ENGINE = InnoDB;

-- Lesson and commitment catalogs.
CREATE TABLE IF NOT EXISTS lesson_catalog (
    lesson_id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    is_custom BOOLEAN NOT NULL DEFAULT FALSE,
    required_for_baptism BOOLEAN NOT NULL DEFAULT FALSE
) ENGINE = InnoDB;

CREATE TABLE IF NOT EXISTS principle_catalog (
    principle_id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    is_custom BOOLEAN NOT NULL DEFAULT FALSE
) ENGINE = InnoDB;

CREATE TABLE IF NOT EXISTS commitment_catalog (
    commitment_id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    is_custom BOOLEAN NOT NULL DEFAULT FALSE,
    required_for_baptism BOOLEAN NOT NULL DEFAULT FALSE
) ENGINE = InnoDB;

-- Keep canceled and rescheduled appointments as rows.
CREATE TABLE IF NOT EXISTS lesson_appointment (
    appointment_id INT AUTO_INCREMENT PRIMARY KEY,
    scheduled_at DATETIME NOT NULL,
    status VARCHAR(20) NOT NULL DEFAULT 'scheduled',
    rescheduled_to_appointment_id INT,
    notes TEXT,
    FOREIGN KEY (rescheduled_to_appointment_id)
        REFERENCES lesson_appointment(appointment_id),
    CHECK (status IN ('scheduled', 'completed', 'canceled', 'rescheduled')),
    CHECK (
        (status = 'rescheduled'
            AND rescheduled_to_appointment_id IS NOT NULL)
        OR
        (status <> 'rescheduled'
            AND rescheduled_to_appointment_id IS NULL)
    ),
    INDEX idx_appointment_scheduled_at (scheduled_at),
    INDEX idx_appointment_status (status)
) ENGINE = InnoDB;

CREATE TABLE IF NOT EXISTS appointment_friend (
    appointment_id INT NOT NULL,
    friend_id INT NOT NULL,
    PRIMARY KEY (appointment_id, friend_id),
    FOREIGN KEY (appointment_id)
        REFERENCES lesson_appointment(appointment_id),
    FOREIGN KEY (friend_id)
        REFERENCES friend_profile(person_id)
) ENGINE = InnoDB;

CREATE TABLE IF NOT EXISTS appointment_member (
    appointment_id INT NOT NULL,
    member_id INT NOT NULL,
    PRIMARY KEY (appointment_id, member_id),
    FOREIGN KEY (appointment_id)
        REFERENCES lesson_appointment(appointment_id),
    FOREIGN KEY (member_id)
        REFERENCES member_profile(person_id)
) ENGINE = InnoDB;

-- Any contact event: lesson, visit, call, and so on.
CREATE TABLE IF NOT EXISTS interaction (
    interaction_id INT AUTO_INCREMENT PRIMARY KEY,
    occurred_at DATETIME NOT NULL,
    interaction_type VARCHAR(100) NOT NULL,
    notes TEXT,
    INDEX idx_interaction_occurred_at (occurred_at)
) ENGINE = InnoDB;

CREATE TABLE IF NOT EXISTS interaction_friend (
    interaction_id INT NOT NULL,
    friend_id INT NOT NULL,
    PRIMARY KEY (interaction_id, friend_id),
    FOREIGN KEY (interaction_id) REFERENCES interaction(interaction_id),
    FOREIGN KEY (friend_id) REFERENCES friend_profile(person_id)
) ENGINE = InnoDB;

CREATE TABLE IF NOT EXISTS interaction_member (
    interaction_id INT NOT NULL,
    member_id INT NOT NULL,
    PRIMARY KEY (interaction_id, member_id),
    FOREIGN KEY (interaction_id) REFERENCES interaction(interaction_id),
    FOREIGN KEY (member_id) REFERENCES member_profile(person_id)
) ENGINE = InnoDB;

-- A completed lesson can link to its appointment and interaction.
CREATE TABLE IF NOT EXISTS lesson_session (
    session_id INT AUTO_INCREMENT PRIMARY KEY,
    appointment_id INT UNIQUE,
    interaction_id INT UNIQUE,
    actual_at DATETIME NOT NULL,
    review_description TEXT,
    notes TEXT,
    FOREIGN KEY (appointment_id)
        REFERENCES lesson_appointment(appointment_id),
    FOREIGN KEY (interaction_id)
        REFERENCES interaction(interaction_id),
    INDEX idx_session_actual_at (actual_at)
) ENGINE = InnoDB;

CREATE TABLE IF NOT EXISTS session_friend (
    session_id INT NOT NULL,
    friend_id INT NOT NULL,
    PRIMARY KEY (session_id, friend_id),
    FOREIGN KEY (session_id) REFERENCES lesson_session(session_id),
    FOREIGN KEY (friend_id) REFERENCES friend_profile(person_id)
) ENGINE = InnoDB;

CREATE TABLE IF NOT EXISTS session_member (
    session_id INT NOT NULL,
    member_id INT NOT NULL,
    PRIMARY KEY (session_id, member_id),
    FOREIGN KEY (session_id) REFERENCES lesson_session(session_id),
    FOREIGN KEY (member_id) REFERENCES member_profile(person_id)
) ENGINE = InnoDB;

CREATE TABLE IF NOT EXISTS session_lesson (
    session_id INT NOT NULL,
    lesson_id INT NOT NULL,
    PRIMARY KEY (session_id, lesson_id),
    FOREIGN KEY (session_id) REFERENCES lesson_session(session_id),
    FOREIGN KEY (lesson_id) REFERENCES lesson_catalog(lesson_id)
) ENGINE = InnoDB;

CREATE TABLE IF NOT EXISTS session_principle (
    session_id INT NOT NULL,
    principle_id INT NOT NULL,
    PRIMARY KEY (session_id, principle_id),
    FOREIGN KEY (session_id) REFERENCES lesson_session(session_id),
    FOREIGN KEY (principle_id) REFERENCES principle_catalog(principle_id)
) ENGINE = InnoDB;

-- Track lesson completion for each friend.
CREATE TABLE IF NOT EXISTS friend_lesson_completion (
    friend_id INT NOT NULL,
    lesson_id INT NOT NULL,
    session_id INT,
    completed_on DATE NOT NULL,
    PRIMARY KEY (friend_id, lesson_id),
    FOREIGN KEY (friend_id) REFERENCES friend_profile(person_id),
    FOREIGN KEY (lesson_id) REFERENCES lesson_catalog(lesson_id),
    FOREIGN KEY (session_id) REFERENCES lesson_session(session_id)
) ENGINE = InnoDB;

-- One row per commitment extended to one friend.
CREATE TABLE IF NOT EXISTS friend_commitment (
    commitment_instance_id INT AUTO_INCREMENT PRIMARY KEY,
    friend_id INT NOT NULL,
    commitment_id INT NOT NULL,
    session_id INT,
    extended_on DATE NOT NULL,
    due_on DATE,
    status VARCHAR(20) NOT NULL DEFAULT 'pending',
    kept_on DATE,
    FOREIGN KEY (friend_id) REFERENCES friend_profile(person_id),
    FOREIGN KEY (commitment_id)
        REFERENCES commitment_catalog(commitment_id),
    FOREIGN KEY (session_id) REFERENCES lesson_session(session_id),
    CHECK (status IN ('pending', 'kept', 'not_kept', 'canceled')),
    CHECK (
        (status = 'kept' AND kept_on IS NOT NULL)
        OR
        (status <> 'kept' AND kept_on IS NULL)
    ),
    INDEX idx_friend_commitment_status (friend_id, status)
) ENGINE = InnoDB;

-- Referrals received by friends, optionally attributed to a member.
CREATE TABLE IF NOT EXISTS referral (
    referral_id INT AUTO_INCREMENT PRIMARY KEY,
    referred_friend_id INT NOT NULL,
    referring_member_id INT,
    referred_on DATE NOT NULL,
    notes TEXT,
    FOREIGN KEY (referred_friend_id)
        REFERENCES friend_profile(person_id),
    FOREIGN KEY (referring_member_id)
        REFERENCES member_profile(person_id),
    INDEX idx_referral_referred_on (referred_on)
) ENGINE = InnoDB;

-- Current baptism date and completed ordinance details for each friend.
CREATE TABLE IF NOT EXISTS friend_baptism (
    friend_id INT PRIMARY KEY,
    date_set DATE,
    scheduled_date DATE,
    ordinance_completed_on DATE,
    area_id INT,
    FOREIGN KEY (friend_id) REFERENCES friend_profile(person_id),
    FOREIGN KEY (area_id) REFERENCES area(area_id),
    CHECK (
        ordinance_completed_on IS NULL
        OR area_id IS NOT NULL
    ),
    INDEX idx_baptism_completed_area_date
        (area_id, ordinance_completed_on)
) ENGINE = InnoDB;