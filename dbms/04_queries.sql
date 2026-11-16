SET search_path TO pathforge, public;

-- @R01
-- R01: READ - Student Career Profile Overview with Active Resume
SELECT 
    u.user_id,
    u.email,
    sp.student_id,
    sp.full_name,
    sp.headline,
    sp.university,
    sp.degree,
    sp.graduation_year,
    sp.cgpa,
    sp.github_username,
    r.resume_id,
    r.file_url AS active_resume_url,
    r.uploaded_at AS resume_uploaded_at
FROM users u
JOIN student_profiles sp ON u.user_id = sp.user_id
LEFT JOIN resumes r ON sp.student_id = r.student_id AND r.is_active = TRUE
WHERE u.email = 'aravind.sharma@example.edu';

-- @R02
-- R02: READ - Student Verified Skills Inventory by Category
SELECT 
    s.category,
    s.name AS skill_name,
    ss.proficiency,
    ss.years_experience,
    ss.verification_source,
    ss.is_verified
FROM student_skills ss
JOIN skills s ON ss.skill_id = s.skill_id
JOIN student_profiles sp ON ss.student_id = sp.student_id
JOIN users u ON sp.user_id = u.user_id
WHERE u.email = 'aravind.sharma@example.edu'
ORDER BY s.category ASC, ss.years_experience DESC;

-- @R03
-- R03: READ - Student Featured Portfolio Projects with Technology Stacks
SELECT 
    p.project_id,
    p.title,
    p.description,
    p.repo_url,
    p.demo_url,
    p.start_date,
    p.end_date,
    COALESCE(string_agg(s.name, ', ' ORDER BY s.name), '') AS tech_stack
FROM projects p
JOIN student_profiles sp ON p.student_id = sp.student_id
JOIN users u ON sp.user_id = u.user_id
LEFT JOIN project_skills ps ON p.project_id = ps.project_id
LEFT JOIN skills s ON ps.skill_id = s.skill_id
WHERE u.email = 'aravind.sharma@example.edu' AND p.is_featured = TRUE
GROUP BY p.project_id, p.title, p.description, p.repo_url, p.demo_url, p.start_date, p.end_date
ORDER BY p.start_date DESC;

-- @R04
-- R04: READ - Active Internships Filtered by Role, Location, and Minimum Stipend
SELECT 
    i.internship_id,
    c.name AS company_name,
    c.location AS company_location,
    i.title,
    i.internship_type,
    i.stipend_amount,
    i.deadline,
    i.status
FROM internships i
JOIN companies c ON i.company_id = c.company_id
WHERE i.status = 'ACTIVE'
  AND (i.internship_type = 'REMOTE' OR i.location ILIKE '%Bengaluru%')
  AND i.stipend_amount >= 25000.00
  AND i.deadline >= CURRENT_DATE
ORDER BY i.deadline ASC, i.stipend_amount DESC
LIMIT 25;

-- @R05
-- R05: READ - Internship Requirement Breakdown (Mandatory vs Preferred)
SELECT 
    ir.requirement_id,
    ir.requirement_type,
    ir.weight,
    ir.min_proficiency,
    COALESCE(s.name, 'General Competency') AS skill_name,
    s.category AS skill_category,
    ir.requirement_text
FROM internship_requirements ir
JOIN internships i ON ir.internship_id = i.internship_id
LEFT JOIN skills s ON ir.skill_id = s.skill_id
WHERE i.title ILIKE '%Backend%'
ORDER BY 
    CASE ir.requirement_type 
        WHEN 'MANDATORY' THEN 1 
        WHEN 'PREFERRED' THEN 2 
        ELSE 3 
    END, 
    ir.weight DESC;

-- @R06
-- R06: READ - Internship Opportunity Details with Employer Information
SELECT 
    i.internship_id,
    i.title AS role_title,
    i.description AS role_description,
    i.location AS role_location,
    i.internship_type,
    i.stipend_amount,
    i.deadline,
    c.company_id,
    c.name AS company_name,
    c.website AS company_website,
    c.industry AS company_industry,
    COUNT(ir.requirement_id) AS total_requirements
FROM internships i
JOIN companies c ON i.company_id = c.company_id
LEFT JOIN internship_requirements ir ON i.internship_id = ir.internship_id
WHERE i.status = 'ACTIVE'
GROUP BY i.internship_id, i.title, i.description, i.location, i.internship_type, 
         i.stipend_amount, i.deadline, c.company_id, c.name, c.website, c.industry
ORDER BY i.created_at DESC
LIMIT 10;

-- @R07
-- R07: READ - Latest Evaluation Diagnostic Report for a Student and Internship
SELECT 
    e.evaluation_id,
    sp.full_name AS student_name,
    c.name AS company_name,
    i.title AS internship_title,
    e.compatibility_score,
    e.coverage_pct,
    e.scoring_version,
    e.summary_notes,
    e.evaluated_at
FROM evaluations e
JOIN student_profiles sp ON e.student_id = sp.student_id
JOIN internships i ON e.internship_id = i.internship_id
JOIN companies c ON i.company_id = c.company_id
WHERE sp.student_id = (SELECT student_id FROM student_profiles LIMIT 1)
ORDER BY e.evaluated_at DESC
LIMIT 1;

-- @R08
-- R08: READ - Requirement-Level Evidence & Diagnostics Breakdown
SELECT 
    ra.assessment_id,
    ir.requirement_type,
    COALESCE(s.name, ir.requirement_text) AS requirement_target,
    ra.match_status,
    ra.match_value,
    ra.confidence_score,
    ra.evidence_source,
    ra.evidence_text,
    ra.explanation
FROM requirement_assessments ra
JOIN evaluations e ON ra.evaluation_id = e.evaluation_id
JOIN internship_requirements ir ON ra.requirement_id = ir.requirement_id
LEFT JOIN skills s ON ir.skill_id = s.skill_id
WHERE e.evaluation_id = (SELECT evaluation_id FROM evaluations ORDER BY evaluated_at DESC LIMIT 1)
ORDER BY 
    CASE ra.match_status 
        WHEN 'MISSING' THEN 1 
        WHEN 'NEEDS_VERIFICATION' THEN 2 
        WHEN 'PARTIALLY_MATCHED' THEN 3 
        ELSE 4 
    END;

-- @R09
-- R09: READ - Prioritized Skill Gaps for an Evaluated Opportunity
SELECT 
    sg.gap_id,
    s.name AS missing_skill,
    s.category AS skill_category,
    sg.priority,
    sg.reason,
    sg.suggested_action
FROM skill_gaps sg
JOIN skills s ON sg.skill_id = s.skill_id
JOIN evaluations e ON sg.evaluation_id = e.evaluation_id
WHERE e.evaluation_id = (SELECT evaluation_id FROM evaluations ORDER BY evaluated_at DESC LIMIT 1)
ORDER BY 
    CASE sg.priority 
        WHEN 'CRITICAL' THEN 1 
        WHEN 'IMPORTANT' THEN 2 
        ELSE 3 
    END;

-- @R10
-- R10: READ - Targeted Bridge Project Recommendations for Closing Gaps
SELECT 
    bp.bridge_project_id,
    bp.title,
    bp.objective,
    bp.difficulty,
    bp.estimated_effort_hours,
    bp.status,
    s.name AS targeted_skill,
    sg.priority AS gap_priority
FROM bridge_projects bp
JOIN evaluations e ON bp.evaluation_id = e.evaluation_id
LEFT JOIN skill_gaps sg ON bp.gap_id = sg.gap_id
LEFT JOIN skills s ON sg.skill_id = s.skill_id
WHERE e.evaluation_id = (SELECT evaluation_id FROM evaluations ORDER BY evaluated_at DESC LIMIT 1)
ORDER BY bp.estimated_effort_hours ASC;

-- @R11
-- R11: READ - Active 7-Day Preparation Roadmap with Overall Progress
SELECT 
    r.roadmap_id,
    r.title AS roadmap_title,
    r.total_days,
    r.status AS roadmap_status,
    i.title AS target_internship,
    c.name AS company_name,
    COUNT(rt.task_id) AS total_tasks,
    COUNT(rt.task_id) FILTER (WHERE rt.is_completed = TRUE) AS completed_tasks,
    ROUND(
        (COUNT(rt.task_id) FILTER (WHERE rt.is_completed = TRUE)::NUMERIC / NULLIF(COUNT(rt.task_id), 0)) * 100, 
        2
    ) AS progress_pct
FROM roadmaps r
JOIN evaluations e ON r.evaluation_id = e.evaluation_id
JOIN internships i ON e.internship_id = i.internship_id
JOIN companies c ON i.company_id = c.company_id
LEFT JOIN roadmap_tasks rt ON r.roadmap_id = rt.roadmap_id
WHERE r.status = 'ACTIVE'
GROUP BY r.roadmap_id, r.title, r.total_days, r.status, i.title, c.name
ORDER BY r.created_at DESC
LIMIT 5;

-- @R12
-- R12: READ - Day-by-Day Roadmap Task Schedule and Verification State
SELECT 
    rt.task_id,
    rt.day_number,
    rt.task_order,
    rt.title AS task_title,
    rt.focus_area,
    rt.expected_outcome,
    rt.estimated_minutes,
    rt.is_completed,
    rt.completed_at
FROM roadmap_tasks rt
JOIN roadmaps r ON rt.roadmap_id = r.roadmap_id
WHERE r.roadmap_id = (SELECT roadmap_id FROM roadmaps WHERE status = 'ACTIVE' ORDER BY created_at DESC LIMIT 1)
ORDER BY rt.day_number ASC, rt.task_order ASC;

-- @R13
-- R13: READ - Application Pipeline Kanban Board for Student
SELECT 
    a.application_id,
    c.name AS company_name,
    i.title AS internship_title,
    a.current_stage,
    a.priority,
    a.applied_date,
    i.deadline,
    e.compatibility_score
FROM applications a
JOIN internships i ON a.internship_id = i.internship_id
JOIN companies c ON i.company_id = c.company_id
LEFT JOIN evaluations e ON a.evaluation_id = e.evaluation_id
JOIN student_profiles sp ON a.student_id = sp.student_id
WHERE sp.student_id = (SELECT student_id FROM student_profiles LIMIT 1)
ORDER BY 
    CASE a.current_stage
        WHEN 'OFFER' THEN 1
        WHEN 'INTERVIEW' THEN 2
        WHEN 'ASSESSMENT' THEN 3
        WHEN 'APPLIED' THEN 4
        WHEN 'READY_TO_APPLY' THEN 5
        WHEN 'PREPARING' THEN 6
        WHEN 'RESEARCHING' THEN 7
        WHEN 'SAVED' THEN 8
        ELSE 9
    END,
    i.deadline ASC;

-- @R14
-- R14: READ - Application Activity Timeline and Audit Trail
SELECT 
    aa.activity_id,
    aa.activity_type,
    aa.old_stage,
    aa.new_stage,
    aa.notes,
    aa.event_timestamp
FROM application_activities aa
JOIN applications a ON aa.application_id = a.application_id
WHERE a.application_id = (SELECT application_id FROM applications ORDER BY updated_at DESC LIMIT 1)
ORDER BY aa.event_timestamp DESC;

-- @R15
-- R15: READ - Career Intelligence Dashboard Summary Aggregation
SELECT 
    sp.student_id,
    sp.full_name,
    COUNT(DISTINCT a.application_id) AS total_applications_tracked,
    COUNT(DISTINCT a.application_id) FILTER (WHERE a.current_stage IN ('APPLIED', 'ASSESSMENT', 'INTERVIEW')) AS active_in_flight_apps,
    COUNT(DISTINCT e.evaluation_id) AS total_evaluations_run,
    ROUND(AVG(e.compatibility_score), 2) AS avg_compatibility_score,
    MAX(e.compatibility_score) AS peak_compatibility_score,
    COUNT(DISTINCT r.roadmap_id) FILTER (WHERE r.status = 'ACTIVE') AS active_prep_roadmaps
FROM student_profiles sp
LEFT JOIN applications a ON sp.student_id = a.student_id
LEFT JOIN evaluations e ON sp.student_id = e.student_id
LEFT JOIN roadmaps r ON sp.student_id = r.student_id
WHERE sp.student_id = (SELECT student_id FROM student_profiles LIMIT 1)
GROUP BY sp.student_id, sp.full_name;

-- @R16
-- R16: READ - Top Matched Opportunities for Student Readiness Ranking
SELECT 
    i.internship_id,
    c.name AS company_name,
    i.title AS internship_title,
    i.location,
    i.stipend_amount,
    e.compatibility_score,
    e.coverage_pct,
    e.evaluated_at
FROM evaluations e
JOIN internships i ON e.internship_id = i.internship_id
JOIN companies c ON i.company_id = c.company_id
WHERE e.student_id = (SELECT student_id FROM student_profiles LIMIT 1)
  AND e.compatibility_score >= 60.00
  AND i.status = 'ACTIVE'
ORDER BY e.compatibility_score DESC, i.stipend_amount DESC
LIMIT 10;

-- @R17
-- R17: READ - High-Demand Market Skills Analysis Across Active Internships
SELECT 
    s.skill_id,
    s.name AS skill_name,
    s.category,
    COUNT(ir.requirement_id) AS occurrence_count,
    ROUND(AVG(ir.weight), 2) AS average_importance_weight,
    COUNT(ir.requirement_id) FILTER (WHERE ir.requirement_type = 'MANDATORY') AS mandatory_count
FROM skills s
JOIN internship_requirements ir ON s.skill_id = ir.skill_id
JOIN internships i ON ir.internship_id = i.internship_id
WHERE i.status = 'ACTIVE'
GROUP BY s.skill_id, s.name, s.category
ORDER BY occurrence_count DESC, mandatory_count DESC
LIMIT 15;

-- @R18
-- R18: READ - Unmet Mandatory Requirements Across Applied Opportunities
SELECT 
    sp.full_name AS student_name,
    c.name AS company_name,
    i.title AS internship_title,
    s.name AS missing_mandatory_skill,
    ir.requirement_text,
    ra.match_status,
    ra.explanation
FROM applications a
JOIN student_profiles sp ON a.student_id = sp.student_id
JOIN internships i ON a.internship_id = i.internship_id
JOIN companies c ON i.company_id = c.company_id
JOIN evaluations e ON a.evaluation_id = e.evaluation_id
JOIN requirement_assessments ra ON e.evaluation_id = ra.evaluation_id
JOIN internship_requirements ir ON ra.requirement_id = ir.requirement_id
LEFT JOIN skills s ON ir.skill_id = s.skill_id
WHERE ir.requirement_type = 'MANDATORY'
  AND ra.match_status IN ('MISSING', 'NEEDS_VERIFICATION')
ORDER BY i.deadline ASC;

-- @R19
-- R19: READ - Student Project Skill Coverage vs Global Catalog
SELECT 
    s.category,
    COUNT(DISTINCT s.skill_id) AS total_skills_in_category,
    COUNT(DISTINCT ss.skill_id) AS student_claimed_skills,
    COUNT(DISTINCT ps.skill_id) AS student_project_evidenced_skills
FROM skills s
LEFT JOIN student_skills ss ON s.skill_id = ss.skill_id 
    AND ss.student_id = (SELECT student_id FROM student_profiles LIMIT 1)
LEFT JOIN (
    SELECT DISTINCT ps_inner.skill_id 
    FROM project_skills ps_inner
    JOIN projects p_inner ON ps_inner.project_id = p_inner.project_id
    WHERE p_inner.student_id = (SELECT student_id FROM student_profiles LIMIT 1)
) ps ON s.skill_id = ps.skill_id
GROUP BY s.category
ORDER BY total_skills_in_category DESC;

-- @R20
-- R20: READ - Expiring Application Deadlines Within Next 7 Days
SELECT 
    sp.student_id,
    sp.full_name AS student_name,
    c.name AS company_name,
    i.title AS internship_title,
    a.current_stage,
    i.deadline,
    (i.deadline - CURRENT_DATE) AS days_remaining
FROM applications a
JOIN student_profiles sp ON a.student_id = sp.student_id
JOIN internships i ON a.internship_id = i.internship_id
JOIN companies c ON i.company_id = c.company_id
WHERE a.current_stage IN ('SAVED', 'RESEARCHING', 'PREPARING', 'READY_TO_APPLY')
  AND i.deadline BETWEEN CURRENT_DATE AND (CURRENT_DATE + INTERVAL '7 days')
ORDER BY days_remaining ASC;

-- @R21
-- R21: READ - Company Hiring Aggregates and Average Stipend Offered
SELECT 
    c.company_id,
    c.name AS company_name,
    c.industry,
    COUNT(i.internship_id) AS total_openings_posted,
    ROUND(AVG(i.stipend_amount), 2) AS average_stipend,
    COUNT(a.application_id) AS total_applications_received,
    COUNT(a.application_id) FILTER (WHERE a.current_stage = 'OFFER') AS total_offers_extended
FROM companies c
JOIN internships i ON c.company_id = i.company_id
LEFT JOIN applications a ON i.internship_id = a.internship_id
GROUP BY c.company_id, c.name, c.industry
ORDER BY total_openings_posted DESC, average_stipend DESC;

-- @R22
-- R22: READ - Student Preparation Task Velocity and Completion Rates
SELECT 
    r.roadmap_id,
    r.title AS roadmap_title,
    COUNT(rt.task_id) AS total_tasks,
    COUNT(rt.task_id) FILTER (WHERE rt.is_completed = TRUE) AS completed_tasks,
    SUM(rt.estimated_minutes) AS total_prep_minutes_allocated,
    SUM(rt.estimated_minutes) FILTER (WHERE rt.is_completed = TRUE) AS completed_prep_minutes,
    ROUND(
        (SUM(rt.estimated_minutes) FILTER (WHERE rt.is_completed = TRUE)::NUMERIC / 
         NULLIF(SUM(rt.estimated_minutes), 0)) * 100, 
        2
    ) AS time_based_completion_pct
FROM roadmaps r
JOIN roadmap_tasks rt ON r.roadmap_id = rt.roadmap_id
WHERE r.student_id = (SELECT student_id FROM student_profiles LIMIT 1)
GROUP BY r.roadmap_id, r.title;

-- @R23
-- R23: READ - Peer Skill Gap Frequency Analysis Across All Evaluations
SELECT 
    s.name AS missing_skill_name,
    s.category,
    COUNT(sg.gap_id) AS gap_occurrence_frequency,
    COUNT(sg.gap_id) FILTER (WHERE sg.priority = 'CRITICAL') AS critical_gap_count,
    COUNT(sg.gap_id) FILTER (WHERE sg.priority = 'IMPORTANT') AS important_gap_count
FROM skill_gaps sg
JOIN skills s ON sg.skill_id = s.skill_id
GROUP BY s.name, s.category
ORDER BY critical_gap_count DESC, gap_occurrence_frequency DESC
LIMIT 10;

-- @R24
-- R24: READ - Multi-Source Verification Audit for High-Confidence Skills
SELECT 
    sp.student_id,
    sp.full_name,
    s.name AS verified_skill,
    ss.proficiency,
    ss.verification_source,
    ss.years_experience
FROM student_skills ss
JOIN student_profiles sp ON ss.student_id = sp.student_id
JOIN skills s ON ss.skill_id = s.skill_id
WHERE ss.is_verified = TRUE
  AND ss.proficiency IN ('ADVANCED', 'EXPERT')
ORDER BY ss.years_experience DESC;

-- @R25
-- R25: READ - Historical Evaluation Drift and Score Trajectory
SELECT 
    e.evaluation_id,
    e.evaluated_at,
    e.scoring_version,
    e.compatibility_score,
    e.coverage_pct,
    LAG(e.compatibility_score) OVER (PARTITION BY e.student_id, e.internship_id ORDER BY e.evaluated_at ASC) AS previous_score,
    ROUND(
        e.compatibility_score - LAG(e.compatibility_score) OVER (PARTITION BY e.student_id, e.internship_id ORDER BY e.evaluated_at ASC), 
        2
    ) AS score_delta
FROM evaluations e
ORDER BY e.evaluated_at ASC
LIMIT 20;

-- @W01
-- W01: WRITE - Update Student Career Profile Headline and Target Role
UPDATE student_profiles
SET 
    headline = 'Full Stack Software Engineer & Distributed Systems Enthusiast',
    target_role = 'Backend Systems Intern',
    updated_at = CURRENT_TIMESTAMP
WHERE student_id = (SELECT student_id FROM student_profiles LIMIT 1);

-- @W02
-- W02: WRITE - Upsert Student Technical Skill Proficiency
INSERT INTO student_skills (
    student_id,
    skill_id,
    proficiency,
    verification_source,
    years_experience,
    is_verified,
    created_at
)
VALUES (
    (SELECT student_id FROM student_profiles LIMIT 1),
    (SELECT skill_id FROM skills WHERE slug = 'postgresql'),
    'ADVANCED',
    'ASSESSMENT',
    2.5,
    TRUE,
    CURRENT_TIMESTAMP
)
ON CONFLICT (student_id, skill_id) DO UPDATE SET
    proficiency = EXCLUDED.proficiency,
    verification_source = EXCLUDED.verification_source,
    years_experience = EXCLUDED.years_experience,
    is_verified = EXCLUDED.is_verified;

-- @W03
-- W03: WRITE - Advance Application Pipeline Stage and Record Audit Activity
WITH updated_app AS (
    UPDATE applications
    SET 
        current_stage = 'APPLIED',
        applied_date = CURRENT_DATE,
        updated_at = CURRENT_TIMESTAMP
    WHERE application_id = (SELECT application_id FROM applications WHERE current_stage = 'READY_TO_APPLY' LIMIT 1)
    RETURNING application_id, 'READY_TO_APPLY'::VARCHAR(30) AS old_stage, current_stage AS new_stage
)
INSERT INTO application_activities (
    activity_id,
    application_id,
    activity_type,
    old_stage,
    new_stage,
    notes,
    event_timestamp
)
SELECT 
    gen_random_uuid(),
    application_id,
    'STAGE_CHANGE',
    old_stage,
    new_stage,
    'Application submitted via official company career portal',
    CURRENT_TIMESTAMP
FROM updated_app;

-- @W04
-- W04: WRITE - Complete Daily Preparation Roadmap Task
UPDATE roadmap_tasks
SET 
    is_completed = TRUE,
    completed_at = CURRENT_TIMESTAMP
WHERE task_id = (
    SELECT task_id 
    FROM roadmap_tasks 
    WHERE is_completed = FALSE 
    ORDER BY day_number ASC, task_order ASC 
    LIMIT 1
);

-- @W05
-- W05: WRITE - Nightly Batch Expiration of Past-Deadline Internships
UPDATE internships
SET 
    status = 'EXPIRED',
    updated_at = CURRENT_TIMESTAMP
WHERE status = 'ACTIVE' 
  AND deadline < CURRENT_DATE;

