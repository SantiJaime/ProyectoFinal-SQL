USE proyecto_final;

-- Creación de funciones
DELIMITER //
CREATE FUNCTION `patient_med_by_id` (id INT)
RETURNS VARCHAR(30)
READS SQL DATA
BEGIN
	DECLARE medicine VARCHAR(30);
    SET medicine = (SELECT m.med_name
    FROM turn t
    LEFT JOIN medicine m ON (t.id_medicine = m.id_medicine)
    WHERE t.id_patient = id
	ORDER BY t.date DESC
	LIMIT 1);
    
	IF medicine IS NULL THEN
		SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'ID de paciente inválida';
    END IF;
    
    RETURN medicine;
END //

DELIMITER //
CREATE FUNCTION `patient_med_test_by_id` (id INT)
RETURNS VARCHAR(50)
READS SQL DATA
BEGIN
	DECLARE med_test VARCHAR(50);
    SET med_test = (SELECT ms.name
    FROM turn t
    LEFT JOIN medical_test ms ON (t.id_req_med_test = ms.id_test)
    WHERE t.id_patient = id
	ORDER BY t.date DESC
	LIMIT 1);
    
	IF med_test IS NULL THEN
		SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'ID de paciente inválida';
    END IF;
    
    RETURN med_test;
END //

DELIMITER //
CREATE FUNCTION `patient_assigned_room_by_id` (id INT)
RETURNS VARCHAR(30)
READS SQL DATA
BEGIN
	DECLARE room VARCHAR(30);
    SET room = (SELECT r.name
    FROM patient p
    LEFT JOIN room r ON (p.id_assigned_room = r.id_room)
    WHERE p.id_patient = id);
    
	IF room IS NULL THEN
		SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'ID de paciente inválida';
    END IF;
    
    RETURN room;
END //

DELIMITER //
CREATE FUNCTION `nurse_assigned_room_by_id` (id INT)
RETURNS VARCHAR(30)
READS SQL DATA
BEGIN
	DECLARE room VARCHAR(30);
    SET room = (SELECT r.name
    FROM nurse n
    LEFT JOIN room r ON (n.id_assigned_room = r.id_room)
    WHERE n.id_nurse = id);
    
	IF room IS NULL THEN
		SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'ID de enfemero inválida';
    END IF;
    
    RETURN room;
END //

-- Creación de Stored Procedures
DELIMITER &&
CREATE PROCEDURE `patient_info_by_id` (IN id INT)
BEGIN
    DECLARE patient_exists INT;

    SELECT COUNT(*) INTO patient_exists
    FROM patient
    WHERE id_patient = id;

    IF patient_exists = 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'ID de paciente inválida';
    ELSE
        SELECT p.full_name AS nombre_paciente, p.age AS edad, p.sex AS sexo, r.name AS sala_asignada
        FROM patient p
        LEFT JOIN room r ON (p.id_assigned_room = r.id_room)
        WHERE p.id_patient = id;
    END IF;
END &&

DELIMITER &&
CREATE PROCEDURE `doctor_info_by_id` (IN id INT)
BEGIN
	DECLARE doctor_exists INT;
    
	SELECT COUNT(*) INTO doctor_exists
    FROM doctor
    WHERE id_doctor = id;

    IF doctor_exists = 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'ID de doctor inválida';
	ELSE
		SELECT d.full_name AS nombre_medico, d.age AS edad, d.sex AS sexo, ms.name AS especialidad_medica
		FROM doctor d
		LEFT JOIN medical_speciality ms ON (d.id_speciality = ms.id_speciality)
		WHERE d.id_doctor = id;
	END IF;
END &&

DELIMITER &&
CREATE PROCEDURE `nurse_info_by_id` (IN id INT)
BEGIN
	DECLARE nurse_exists INT;
    
	SELECT COUNT(*) INTO nurse_exists
    FROM nurse
    WHERE id_nurse = id;

    IF nurse_exists = 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'ID de enfermero inválida';
	ELSE
		SELECT n.full_name AS nombre_enfermero, n.age AS edad, n.sex AS sexo, r.name AS sala_asignada
		FROM nurse n
		LEFT JOIN room r ON (n.id_assigned_room = r.id_room)
		WHERE n.id_nurse = id;
	END IF;
END &&

DELIMITER &&
CREATE PROCEDURE `patient_diagnosis_by_id` (IN id INT)
BEGIN
    DECLARE patient_exists INT;

    SELECT COUNT(*) INTO patient_exists
    FROM patient_diagnosis
    WHERE id_patient = id;

    IF patient_exists = 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'ID de paciente inválida';
    ELSE
		SELECT p.full_name AS nombre_paciente, ds.name AS diagnostico, pd.date AS fecha_diagnostico
		FROM patient_diagnosis pd
		LEFT JOIN patient p ON (p.id_patient = pd.id_patient)
		LEFT JOIN disease ds ON (ds.id_disease = pd.id_disease)
		WHERE pd.id_patient = id;
	END IF;
END &&

DELIMITER &&
CREATE PROCEDURE `turn_info_by_patient_id` (IN id INT)
BEGIN
    DECLARE patient_exists INT;

    SELECT COUNT(*) INTO patient_exists
    FROM turn
    WHERE id_patient = id;

    IF patient_exists = 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'ID de paciente inválida';
    ELSE
		SELECT p.full_name AS nombre_paciente, d.full_name AS nombre_medico_asignado,
		m.med_name AS nombre_medicina_recetada, mt.name AS estudio_medico
		FROM turn t
		LEFT JOIN patient p ON (p.id_patient = t.id_patient)
		LEFT JOIN doctor d ON (d.id_doctor = t.id_assigned_doctor)
		LEFT JOIN medicine m ON (m.id_medicine = t.id_medicine)
		LEFT JOIN medical_test mt ON (mt.id_test = t.id_req_med_test)
		WHERE t.id_patient = id;
    END IF;
END &&

DELIMITER &&
CREATE PROCEDURE `insert_patient` (IN patient_name VARCHAR(100), IN patient_age INT, IN patient_sex VARCHAR(1), IN id_room INT)
BEGIN
	IF patient_age < 0 OR patient_age > 100 THEN
		SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'La edad ingresada es inválida';
	ELSEIF patient_sex != 'M' AND patient_sex != 'H' THEN
		SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'El sexo del paciente ingresado es inválido, debe ser "H" (hombre) o "M" (mujer)';
	ELSEIF id_room NOT BETWEEN 1 AND 31 THEN
		SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'ID de sala asignada al paciente inválida';
    ELSE
		INSERT INTO patient (full_name, age, sex, id_assigned_room) 
			VALUES (patient_name, patient_age, patient_sex, id_room);
	END IF;
END &&

DELIMITER &&
CREATE PROCEDURE `update_patient_room_by_id` (IN patient_id INT, IN id_room INT)
BEGIN
    DECLARE patient_exists INT;

    SELECT COUNT(*) INTO patient_exists
    FROM patient
    WHERE id_patient = patient_id;
    
	IF patient_exists = 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'ID de paciente inválida';
    ELSEIF id_room NOT BETWEEN 1 AND 31 THEN
		SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'ID de sala asignada al paciente inválida';	
    ELSE
		UPDATE patient
		SET id_assigned_room = id_room
		WHERE id_patient = patient_id;
	END IF;
END &&

DELIMITER &&
CREATE PROCEDURE `delete_old_turn_by_patient_id` (IN patient_id INT)
BEGIN
    DECLARE patient_exists INT;
   DECLARE min_date DATE;
   
    SELECT COUNT(*) INTO patient_exists
    FROM turn
    WHERE id_patient = patient_id;
    
	IF patient_exists = 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'ID de paciente inválida';
    ELSE
        SELECT MIN(date) INTO min_date
        FROM turn
        WHERE id_patient = patient_id;
        
        DELETE FROM turn
        WHERE id_patient = patient_id AND date = min_date
        LIMIT 1;
    END IF;
END &&

-- Creación de Triggers
DELIMITER $$
CREATE TRIGGER `audit_log_turn_delete`
BEFORE DELETE ON turn
FOR EACH ROW
BEGIN
	INSERT INTO audit_log_turn
		VALUES (OLD.id_turn, OLD.id_patient, NOW());
END $$

DELIMITER $$
CREATE TRIGGER `patient_default_room`
BEFORE INSERT ON patient
FOR EACH ROW
BEGIN
	IF NEW.id_assigned_room IS NULL OR NEW.id_assigned_room NOT BETWEEN 1 AND 31 THEN
		SET NEW.id_assigned_room = 4;
	END IF;
END $$