-- Projenin ana senaryosu:
-- Bir lojistik þirketinin ticari akýþýný yönetmek için bir sistem oluþturulacak. Bu sistemde gelen/giden yükler, týrlar, þoförler ve nakliye iþlemleri gibi tablolar yer alacak.


-- Týrlar tablosu
CREATE TABLE TIRLAR (
    TIRID INT PRIMARY KEY IDENTITY(1,1),
    Plaka NVARCHAR(15) NOT NULL,
    Marka NVARCHAR(50),
    Model NVARCHAR(50),
    Kapasite INT NOT NULL -- Kilogram cinsinden
);

-- Þoförler tablosu
CREATE TABLE SOFORLER (
    SoforID INT PRIMARY KEY IDENTITY(1,1),
    AdSoyad NVARCHAR(255) NOT NULL,
    Telefon NVARCHAR(15),
    EhliyetNo NVARCHAR(50),
    DeneyimYili INT
);

-- Yükler tablosu
CREATE TABLE YUKLER (
    YukID INT PRIMARY KEY IDENTITY(1,1),
    YukAdi NVARCHAR(255) NOT NULL,
    Agirlik INT NOT NULL, -- Kilogram cinsinden
    VarisNoktasi NVARCHAR(255),
    YuklenmeTarihi DATE
);

-- Nakliye iþlemleri tablosu
CREATE TABLE NAKLIYE_ISLEMLERI (
    IslemID INT PRIMARY KEY IDENTITY(1,1),
    TIRID INT FOREIGN KEY REFERENCES TIRLAR(TIRID),
    SoforID INT FOREIGN KEY REFERENCES SOFORLER(SoforID),
    YukID INT FOREIGN KEY REFERENCES YUKLER(YukID),
    CikisTarihi DATE NOT NULL,
    TeslimTarihi DATE
);

--Insert sorgularý:
-- Týrlar tablosu için örnek veriler
INSERT INTO TIRLAR (Plaka, Marka, Model, Kapasite) VALUES
('59DNS12', 'Mercedes', 'Actros', 20000),
('06ABC34', 'Scania', 'R500', 25000),
('35DEF56', 'Volvo', 'FH16', 30000);

-- Þoförler tablosu için örnek veriler
INSERT INTO SOFORLER (AdSoyad, Telefon, EhliyetNo, DeneyimYili) VALUES
('Okan Umut Özen', '05301234567', 'TR123456', 5),
('Kerem Kurnaz', '05407654321', 'TR654321', 10),
('Selinay Mete', '05509876543', 'TR987654', 3);

-- Yükler tablosu için örnek veriler
INSERT INTO YUKLER (YukAdi, Agirlik, VarisNoktasi, YuklenmeTarihi) VALUES
('Mobilya', 5000, 'Ankara', '2025-01-01'),
('Elektronik Eþya', 3000, 'Ýzmir', '2025-01-02'),
('Gýda Ürünleri', 7000, 'Antalya', '2025-01-03');

-- Nakliye iþlemleri tablosu için örnek veriler
INSERT INTO NAKLIYE_ISLEMLERI (TIRID, SoforID, YukID, CikisTarihi, TeslimTarihi) VALUES
(1, 1, 1, '2025-01-01', '2025-01-02'),
(2, 2, 2, '2025-01-02', NULL),
(3, 3, 3, '2025-01-03', '2025-01-04');

GO
--Stored Procedure Sorularý ve Cevaplarý
--1)Týrlar için kapasite kontrolü yapan bir stored procedure
CREATE PROCEDURE GetTirlarByCapacity
    @MinCapacity INT
AS
BEGIN
    SELECT TIRID, Plaka, Marka, Model, Kapasite
    FROM TIRLAR
    WHERE Kapasite >= @MinCapacity;
END;

-- Çalýþtýrma
EXEC GetTirlarByCapacity @MinCapacity = 25000;

GO
-- 2)Yüklerin teslim tarihine göre filtrelenmesi saðlayacak sorgu
CREATE PROCEDURE GetYuklerByDeliveryDate
    @DeliveryDate DATE
AS
BEGIN
    SELECT YukAdi, Agirlik, VarisNoktasi, YuklenmeTarihi
    FROM YUKLER
    WHERE YuklenmeTarihi <= @DeliveryDate;
END;

-- Çalýþtýrma
EXEC GetYuklerByDeliveryDate @DeliveryDate = '2025-01-03';

GO
--3)Þoförlerin deneyim yýlýna göre listelemeye yarayan sorgu
CREATE PROCEDURE GetDriversByExperience
    @MinExperience INT
AS
BEGIN
    SELECT SoforID, AdSoyad, Telefon, EhliyetNo, DeneyimYili
    FROM SOFORLER
    WHERE DeneyimYili >= @MinExperience;
END;

-- Çalýþtýrma
EXEC GetDriversByExperience @MinExperience = 5;

GO

--View Sorgularý 
--1)Týr ve þoför bilgilerini birleþtiren view sorgusu

CREATE VIEW ViewTirSofor
AS
SELECT T.TIRID, T.Plaka, T.Kapasite, S.AdSoyad, S.DeneyimYili
FROM TIRLAR T
JOIN SOFORLER S ON T.TIRID = S.SoforID;
GO

-- Görüntüleme
SELECT * FROM ViewTirSofor;

GO
--2)Yüklerin varýþ noktasýna göre sýralandýðý view  sorgusu
CREATE VIEW ViewYuklerByDestination
AS
SELECT YukAdi, Agirlik, VarisNoktasi, YuklenmeTarihi
FROM YUKLER;
GO

-- Görüntüleme
SELECT * FROM ViewYuklerByDestination
ORDER BY VarisNoktasi;

GO
--3)Nakliye iþlemlerinin durumunu gösteren view sorgusu
CREATE VIEW ViewNakliyeDurum
AS
SELECT I.IslemID, T.Plaka, S.AdSoyad, Y.YukAdi, I.CikisTarihi, I.TeslimTarihi,
       CASE WHEN I.TeslimTarihi IS NULL THEN 'Devam Ediyor' ELSE 'Tamamlandý' END AS Durum
FROM NAKLIYE_ISLEMLERI I
JOIN TIRLAR T ON I.TIRID = T.TIRID
JOIN SOFORLER S ON I.SoforID = S.SoforID
JOIN YUKLER Y ON I.YukID = Y.YukID;
GO

-- Görüntüleme
SELECT * FROM ViewNakliyeDurum;
GO

--Trigger
--1)Yeni yük eklendiðinde kapasite kontrolü yapan trigger sorgusu
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
        RAISERROR('Týr kapasitesi yetersiz.', 16, 1);
        ROLLBACK;
    END
END;
GO
-- Bu trigger, yeni bir nakliye iþlemi eklerken tetiklenir.

--2)Yüklerin teslim tarihini güncelleyen trigger sorgusu
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

--3)Týrýn kapasitesinin güncellenmesiyle ilgili trigger sorgusu
CREATE TRIGGER UpdateTirCapacity
ON TIRLAR
FOR UPDATE
AS
BEGIN
    DECLARE @TIRID INT, @YeniKapasite INT;
    
    SELECT @TIRID = TIRID, @YeniKapasite = Kapasite FROM INSERTED;
    
    IF EXISTS (SELECT * FROM NAKLIYE_ISLEMLERI WHERE TIRID = @TIRID AND YukID IN (SELECT YukID FROM YUKLER WHERE Agirlik > @YeniKapasite))
    BEGIN
        RAISERROR('Týr kapasitesinin deðiþmesi nedeniyle taþýma iþlemi iptal edilmiþtir.', 16, 1);
        ROLLBACK;
    END
END;
GO
-- Function Örnekleri
--1)Yüklerin toplam aðýrlýðýný hesaplayan function sorgusu
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

--2)Týrýn kullanýlabilir kapasitesini hesaplayan function sorgusu
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

--3)Þoförün deneyim yýlýný döndüren function sorgusu
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

--Ýç Ýçe Select 
--1)Týrlarýn plakasýný ve taþýdýðý yüklerin toplam aðýrlýðýný listeleyen iç içe select sorgusu
SELECT T.Plaka, 
       (SELECT SUM(Agirlik) 
        FROM YUKLER Y 
        JOIN NAKLIYE_ISLEMLERI N ON Y.YukID = N.YukID 
        WHERE N.TIRID = T.TIRID) AS ToplamAgirlik
FROM TIRLAR T;
GO

--2)Þoförlerin taþýdýðý toplam yük miktarýný listeleyen iç içe select sorgusu
SELECT S.AdSoyad, 
       (SELECT SUM(Y.Agirlik) 
        FROM YUKLER Y 
        JOIN NAKLIYE_ISLEMLERI N ON Y.YukID = N.YukID 
        WHERE N.SoforID = S.SoforID) AS ToplamYukAgirlik
FROM SOFORLER S;
GO


--3)Yüklerin varýþ noktasýna göre sýralandýðý ve her bir yükün taþýma durumunu gösteren iç içe select sorgusu
SELECT Y.YukAdi, Y.VarisNoktasi, 
       (SELECT CASE WHEN I.TeslimTarihi IS NULL THEN 'Devam Ediyor' ELSE 'Tamamlandý' END 
        FROM NAKLIYE_ISLEMLERI I 
        WHERE I.YukID = Y.YukID) AS Durum
FROM YUKLER Y;
















