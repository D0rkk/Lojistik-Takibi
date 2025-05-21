-- Projenin ana senaryosu:
-- Bir lojistik �irketinin ticari ak���n� y�netmek i�in bir sistem olu�turulacak. Bu sistemde gelen/giden y�kler, t�rlar, �of�rler ve nakliye i�lemleri gibi tablolar yer alacak.


-- T�rlar tablosu
CREATE TABLE TIRLAR (
    TIRID INT PRIMARY KEY IDENTITY(1,1),
    Plaka NVARCHAR(15) NOT NULL,
    Marka NVARCHAR(50),
    Model NVARCHAR(50),
    Kapasite INT NOT NULL -- Kilogram cinsinden
);

-- �of�rler tablosu
CREATE TABLE SOFORLER (
    SoforID INT PRIMARY KEY IDENTITY(1,1),
    AdSoyad NVARCHAR(255) NOT NULL,
    Telefon NVARCHAR(15),
    EhliyetNo NVARCHAR(50),
    DeneyimYili INT
);

-- Y�kler tablosu
CREATE TABLE YUKLER (
    YukID INT PRIMARY KEY IDENTITY(1,1),
    YukAdi NVARCHAR(255) NOT NULL,
    Agirlik INT NOT NULL, -- Kilogram cinsinden
    VarisNoktasi NVARCHAR(255),
    YuklenmeTarihi DATE
);

-- Nakliye i�lemleri tablosu
CREATE TABLE NAKLIYE_ISLEMLERI (
    IslemID INT PRIMARY KEY IDENTITY(1,1),
    TIRID INT FOREIGN KEY REFERENCES TIRLAR(TIRID),
    SoforID INT FOREIGN KEY REFERENCES SOFORLER(SoforID),
    YukID INT FOREIGN KEY REFERENCES YUKLER(YukID),
    CikisTarihi DATE NOT NULL,
    TeslimTarihi DATE
);

--Insert sorgular�:
-- T�rlar tablosu i�in �rnek veriler
INSERT INTO TIRLAR (Plaka, Marka, Model, Kapasite) VALUES
('59DNS12', 'Mercedes', 'Actros', 20000),
('06ABC34', 'Scania', 'R500', 25000),
('35DEF56', 'Volvo', 'FH16', 30000);

-- �of�rler tablosu i�in �rnek veriler
INSERT INTO SOFORLER (AdSoyad, Telefon, EhliyetNo, DeneyimYili) VALUES
('Okan Umut �zen', '05301234567', 'TR123456', 5),
('Kerem Kurnaz', '05407654321', 'TR654321', 10),
('Selinay Mete', '05509876543', 'TR987654', 3);

-- Y�kler tablosu i�in �rnek veriler
INSERT INTO YUKLER (YukAdi, Agirlik, VarisNoktasi, YuklenmeTarihi) VALUES
('Mobilya', 5000, 'Ankara', '2025-01-01'),
('Elektronik E�ya', 3000, '�zmir', '2025-01-02'),
('G�da �r�nleri', 7000, 'Antalya', '2025-01-03');

-- Nakliye i�lemleri tablosu i�in �rnek veriler
INSERT INTO NAKLIYE_ISLEMLERI (TIRID, SoforID, YukID, CikisTarihi, TeslimTarihi) VALUES
(1, 1, 1, '2025-01-01', '2025-01-02'),
(2, 2, 2, '2025-01-02', NULL),
(3, 3, 3, '2025-01-03', '2025-01-04');

GO
--Stored Procedure Sorular� ve Cevaplar�
--1)T�rlar i�in kapasite kontrol� yapan bir stored procedure
CREATE PROCEDURE GetTirlarByCapacity
    @MinCapacity INT
AS
BEGIN
    SELECT TIRID, Plaka, Marka, Model, Kapasite
    FROM TIRLAR
    WHERE Kapasite >= @MinCapacity;
END;

-- �al��t�rma
EXEC GetTirlarByCapacity @MinCapacity = 25000;

GO
-- 2)Y�klerin teslim tarihine g�re filtrelenmesi sa�layacak sorgu
CREATE PROCEDURE GetYuklerByDeliveryDate
    @DeliveryDate DATE
AS
BEGIN
    SELECT YukAdi, Agirlik, VarisNoktasi, YuklenmeTarihi
    FROM YUKLER
    WHERE YuklenmeTarihi <= @DeliveryDate;
END;

-- �al��t�rma
EXEC GetYuklerByDeliveryDate @DeliveryDate = '2025-01-03';

GO
--3)�of�rlerin deneyim y�l�na g�re listelemeye yarayan sorgu
CREATE PROCEDURE GetDriversByExperience
    @MinExperience INT
AS
BEGIN
    SELECT SoforID, AdSoyad, Telefon, EhliyetNo, DeneyimYili
    FROM SOFORLER
    WHERE DeneyimYili >= @MinExperience;
END;

-- �al��t�rma
EXEC GetDriversByExperience @MinExperience = 5;

GO

--View Sorgular� 
--1)T�r ve �of�r bilgilerini birle�tiren view sorgusu

CREATE VIEW ViewTirSofor
AS
SELECT T.TIRID, T.Plaka, T.Kapasite, S.AdSoyad, S.DeneyimYili
FROM TIRLAR T
JOIN SOFORLER S ON T.TIRID = S.SoforID;
GO

-- G�r�nt�leme
SELECT * FROM ViewTirSofor;

GO
--2)Y�klerin var�� noktas�na g�re s�raland��� view  sorgusu
CREATE VIEW ViewYuklerByDestination
AS
SELECT YukAdi, Agirlik, VarisNoktasi, YuklenmeTarihi
FROM YUKLER;
GO

-- G�r�nt�leme
SELECT * FROM ViewYuklerByDestination
ORDER BY VarisNoktasi;

GO
--3)Nakliye i�lemlerinin durumunu g�steren view sorgusu
CREATE VIEW ViewNakliyeDurum
AS
SELECT I.IslemID, T.Plaka, S.AdSoyad, Y.YukAdi, I.CikisTarihi, I.TeslimTarihi,
       CASE WHEN I.TeslimTarihi IS NULL THEN 'Devam Ediyor' ELSE 'Tamamland�' END AS Durum
FROM NAKLIYE_ISLEMLERI I
JOIN TIRLAR T ON I.TIRID = T.TIRID
JOIN SOFORLER S ON I.SoforID = S.SoforID
JOIN YUKLER Y ON I.YukID = Y.YukID;
GO

-- G�r�nt�leme
SELECT * FROM ViewNakliyeDurum;
GO

--Trigger
--1)Yeni y�k eklendi�inde kapasite kontrol� yapan trigger sorgusu
CREATE TRIGGER CheckCapacityBeforeInsert
ON NAKLIYE_ISLEMLERI
FOR INSERT
AS
BEGIN
    DECLARE @TIRID INT, @YukID INT, @YukAgirlik INT, @Kapasite INT;
    
    SELECT @TIRID = TIRID, @YukID = YukID FROM INSERTED;
    SELECT @YukAgirlik = Agirlik FROM YUKLER WHERE YukID = @YukID;
    SELECT @Kapasite = Kapasite FROM TIRLAR WHERE TIRID = @TIRID;
    
    IF @YukAgirlik > @Kapasite
    BEGIN
        RAISERROR('T�r kapasitesi yetersiz.', 16, 1);
        ROLLBACK;
    END
END;
GO
-- Bu trigger, yeni bir nakliye i�lemi eklerken tetiklenir.

--2)Y�klerin teslim tarihini g�ncelleyen trigger sorgusu
CREATE TRIGGER UpdateDeliveryDate
ON NAKLIYE_ISLEMLERI
FOR UPDATE
AS
BEGIN
    DECLARE @IslemID INT, @TeslimTarihi DATE;
    
    SELECT @IslemID = IslemID, @TeslimTarihi = TeslimTarihi FROM INSERTED;
    
    IF @TeslimTarihi IS NOT NULL
    BEGIN
        UPDATE YUKLER
        SET YuklenmeTarihi = @TeslimTarihi
        WHERE YukID = (SELECT YukID FROM NAKLIYE_ISLEMLERI WHERE IslemID = @IslemID);
    END
END;

GO

--3)T�r�n kapasitesinin g�ncellenmesiyle ilgili trigger sorgusu
CREATE TRIGGER UpdateTirCapacity
ON TIRLAR
FOR UPDATE
AS
BEGIN
    DECLARE @TIRID INT, @YeniKapasite INT;
    
    SELECT @TIRID = TIRID, @YeniKapasite = Kapasite FROM INSERTED;
    
    IF EXISTS (SELECT * FROM NAKLIYE_ISLEMLERI WHERE TIRID = @TIRID AND YukID IN (SELECT YukID FROM YUKLER WHERE Agirlik > @YeniKapasite))
    BEGIN
        RAISERROR('T�r kapasitesinin de�i�mesi nedeniyle ta��ma i�lemi iptal edilmi�tir.', 16, 1);
        ROLLBACK;
    END
END;
GO
-- Function �rnekleri
--1)Y�klerin toplam a��rl���n� hesaplayan function sorgusu
CREATE FUNCTION CalculateTotalWeight (@Date DATE)
RETURNS INT
AS
BEGIN
    DECLARE @TotalWeight INT;
    
    SELECT @TotalWeight = SUM(Agirlik) FROM YUKLER WHERE YuklenmeTarihi <= @Date;
    
    RETURN @TotalWeight;
END;
GO

-- Kullanma
SELECT dbo.CalculateTotalWeight('2025-01-03') AS ToplamAgirlik;
GO

--2)T�r�n kullan�labilir kapasitesini hesaplayan function sorgusu
CREATE FUNCTION CalculateAvailableCapacity (@TIRID INT)
RETURNS INT
AS
BEGIN
    DECLARE @TotalWeight INT, @Capacity INT, @AvailableCapacity INT;
    
    SELECT @Capacity = Kapasite FROM TIRLAR WHERE TIRID = @TIRID;
    SELECT @TotalWeight = SUM(Agirlik) FROM YUKLER WHERE YukID IN (SELECT YukID FROM NAKLIYE_ISLEMLERI WHERE TIRID = @TIRID);
    
    SET @AvailableCapacity = @Capacity - @TotalWeight;
    
    RETURN @AvailableCapacity;
END;
GO

-- Kullanma
SELECT dbo.CalculateAvailableCapacity(1) AS KullanilabilirKapasite;
GO

--3)�of�r�n deneyim y�l�n� d�nd�ren function sorgusu
CREATE FUNCTION GetDriverExperience (@SoforID INT)
RETURNS INT
AS
BEGIN
    DECLARE @Experience INT;
    
    SELECT @Experience = DeneyimYili FROM SOFORLER WHERE SoforID = @SoforID;
    
    RETURN @Experience;
END;
GO

-- Kullanma
SELECT dbo.GetDriverExperience(2) AS DeneyimYili;

--�� ��e Select 
--1)T�rlar�n plakas�n� ve ta��d��� y�klerin toplam a��rl���n� listeleyen i� i�e select sorgusu
SELECT T.Plaka, 
       (SELECT SUM(Agirlik) 
        FROM YUKLER Y 
        JOIN NAKLIYE_ISLEMLERI N ON Y.YukID = N.YukID 
        WHERE N.TIRID = T.TIRID) AS ToplamAgirlik
FROM TIRLAR T;
GO

--2)�of�rlerin ta��d��� toplam y�k miktar�n� listeleyen i� i�e select sorgusu
SELECT S.AdSoyad, 
       (SELECT SUM(Y.Agirlik) 
        FROM YUKLER Y 
        JOIN NAKLIYE_ISLEMLERI N ON Y.YukID = N.YukID 
        WHERE N.SoforID = S.SoforID) AS ToplamYukAgirlik
FROM SOFORLER S;
GO


--3)Y�klerin var�� noktas�na g�re s�raland��� ve her bir y�k�n ta��ma durumunu g�steren i� i�e select sorgusu
SELECT Y.YukAdi, Y.VarisNoktasi, 
       (SELECT CASE WHEN I.TeslimTarihi IS NULL THEN 'Devam Ediyor' ELSE 'Tamamland�' END 
        FROM NAKLIYE_ISLEMLERI I 
        WHERE I.YukID = Y.YukID) AS Durum
FROM YUKLER Y;
















