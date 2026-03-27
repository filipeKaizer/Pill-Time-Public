CREATE DATABASE IF NOT EXISTS pill;
USE pill;

-- =========================
-- Tabela: Remedio
-- =========================
CREATE TABLE RemedyType (
    id_type INT AUTO_INCREMENT PRIMARY KEY,
    type_name VARCHAR(100) NOT NULL UNIQUE
);

CREATE TABLE Remedy (
    id_remedy INT AUTO_INCREMENT PRIMARY KEY,
    remedy_name VARCHAR(255) NOT NULL,
    id_type INT NOT NULL,
    remedy_use VARCHAR(100) NOT NULL,
    FOREIGN KEY (id_type) REFERENCES RemedyType(id_type)
);

-- =========================
-- Tabela: Dosagem
-- =========================
CREATE TABLE Dosage (
    id_dosage INT AUTO_INCREMENT PRIMARY KEY,
    dose DECIMAL(5,1) NOT NULL
);

-- =========================
-- Tabela: Relacionamento N:N
-- =========================
CREATE TABLE Remedy_Dosage (
    id_remedy INT,
    id_dosage INT,

    PRIMARY KEY (id_remedy, id_dosage),

    CONSTRAINT fk_rd_remedy
        FOREIGN KEY (id_remedy)
        REFERENCES Remedy(id_remedy)
        ON DELETE CASCADE
        ON UPDATE CASCADE,

    CONSTRAINT fk_rd_dosage
        FOREIGN KEY (id_dosage)
        REFERENCES Dosage(id_dosage)
        ON DELETE CASCADE
        ON UPDATE CASCADE
);

-- =========================
-- Tabela: Imagem (1:N)
-- =========================
CREATE TABLE Image (
    id_image INT AUTO_INCREMENT PRIMARY KEY,
    id_remedy INT NOT NULL,
    image_path VARCHAR(255) NOT NULL,

    CONSTRAINT fk_image_remedy
        FOREIGN KEY (id_remedy)
        REFERENCES Remedy(id_remedy)
        ON DELETE CASCADE
        ON UPDATE CASCADE
);