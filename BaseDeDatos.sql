CREATE DATABASE TiendaOnline;
GO
USE TiendaOnline;
GO

CREATE TABLE Clientes (
    ClienteID INT PRIMARY KEY IDENTITY(1,1),
    Nombre NVARCHAR(100) NOT NULL,
    Apellido NVARCHAR(100) NOT NULL,
    CorreoElectronico NVARCHAR(100) NOT NULL UNIQUE,
    NombreUsuario NVARCHAR(50) NOT NULL UNIQUE,
    Contrasena NVARCHAR(255) NOT NULL
);

CREATE TABLE SesionesClientes (
    SesionID INT PRIMARY KEY IDENTITY(1,1),
    ClienteID INT NOT NULL,
    FechaInicio DATETIME DEFAULT GETDATE(),
    IP NVARCHAR(50),
    FOREIGN KEY (ClienteID) REFERENCES Clientes(ClienteID)
);



CREATE TABLE Administradores (
    AdministradorID INT PRIMARY KEY IDENTITY(1,1),
    NombreUsuario NVARCHAR(50) NOT NULL UNIQUE,
    Contrasena NVARCHAR(255) NOT NULL
);

INSERT INTO Administradores (NombreUsuario, Contrasena)
VALUES ('admin', 'admin');

CREATE TABLE Productos (
    ProductoID INT PRIMARY KEY IDENTITY(1,1),
    Nombre NVARCHAR(100) NOT NULL,
    Precio DECIMAL(10, 2) NOT NULL,
    Stock INT NOT NULL
);

INSERT INTO Productos (Nombre, Precio, Stock)
VALUES 
    ('Razer Viper Mini', 100.00, 50),
    ('Logitech G502 Hero', 200.00, 30),
    ('Razer Mamba', 150.00, 20),
    ('Teclado Logitech G213 Prodigy', 250.00, 10),
    ('Audiofonos Bose Deluxe', 300.00, 5);

CREATE TABLE AuditoriaCRUD (
    AuditoriaID INT PRIMARY KEY IDENTITY(1,1),
    TipoOperacion NVARCHAR(10) NOT NULL,  -- CREATE, READ, UPDATE, DELETE
    Tabla NVARCHAR(50) NOT NULL,
    RegistroID INT NOT NULL,
    Usuario NVARCHAR(50) NOT NULL,
    Fecha DATETIME DEFAULT GETDATE()
);

CREATE TABLE Pedidos (
    PedidoID INT PRIMARY KEY IDENTITY(1,1),
    ClienteID INT NOT NULL,
    ProductoID INT NOT NULL,
    Cantidad INT NOT NULL,
    FechaCompra DATETIME DEFAULT GETDATE(),
    FOREIGN KEY (ClienteID) REFERENCES Clientes(ClienteID),
    FOREIGN KEY (ProductoID) REFERENCES Productos(ProductoID)
);

CREATE TABLE PedidosCancelados (
    PedidoCanceladoID INT PRIMARY KEY IDENTITY(1,1),
    PedidoID INT NOT NULL,
    ClienteID INT NOT NULL,
    ProductoID INT NOT NULL,
    Cantidad INT NOT NULL,
    FechaCancelacion DATETIME DEFAULT GETDATE(),
    FOREIGN KEY (PedidoID) REFERENCES Pedidos(PedidoID),
    FOREIGN KEY (ClienteID) REFERENCES Clientes(ClienteID),
    FOREIGN KEY (ProductoID) REFERENCES Productos(ProductoID)
);

CREATE TABLE Ventas (
    VentaID INT PRIMARY KEY IDENTITY(1,1),
    ClienteID INT NOT NULL,
    NombreUsuario NVARCHAR(50) NOT NULL,
    NombreProducto NVARCHAR(100) NOT NULL,
    Cantidad INT NOT NULL,
    TotalCompra DECIMAL(10, 2) NOT NULL,
    FechaVenta DATETIME DEFAULT GETDATE(),
    FOREIGN KEY (ClienteID) REFERENCES Clientes(ClienteID)
);

CREATE INDEX idx_Productos_nombres ON Productos(Nombre);
CREATE INDEX idx_Cliente_email ON Clientes(CorreoElectronico);
CREATE INDEX idx_Pedidos_fechaPedido ON Pedidos(FechaCompra);

CREATE PROCEDURE RegistrarPedido
    @ClienteID INT,
    @ProductoID INT,
    @Cantidad INT
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        BEGIN TRANSACTION;
        
        DECLARE @StockActual INT;
        SELECT @StockActual = Stock FROM Productos WHERE ProductoID = @ProductoID;
        
        IF @StockActual < @Cantidad
        BEGIN
            THROW 50001, 'Stock insuficiente para realizar el pedido.', 1;
        END

        INSERT INTO Pedidos (ClienteID, ProductoID, Cantidad, FechaCompra)
        VALUES (@ClienteID, @ProductoID, @Cantidad, GETDATE());

        UPDATE Productos
        SET Stock = Stock - @Cantidad
        WHERE ProductoID = @ProductoID;

        DECLARE @NuevoPedidoID INT;
        SELECT @NuevoPedidoID = SCOPE_IDENTITY();

        DECLARE @NombreUsuario NVARCHAR(50);
        DECLARE @NombreProducto NVARCHAR(100);
        DECLARE @Precio DECIMAL(10, 2);
        DECLARE @TotalCompra DECIMAL(10, 2);

        SELECT @NombreUsuario = NombreUsuario FROM Clientes WHERE ClienteID = @ClienteID;
        SELECT @NombreProducto = Nombre, @Precio = Precio FROM Productos WHERE ProductoID = @ProductoID;
        SET @TotalCompra = @Cantidad * @Precio;

        INSERT INTO Ventas (ClienteID, NombreUsuario, NombreProducto, Cantidad, TotalCompra, FechaVenta)
        VALUES (@ClienteID, @NombreUsuario, @NombreProducto, @Cantidad, @TotalCompra, GETDATE());

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        ROLLBACK TRANSACTION;
        THROW;
    END CATCH;
END


CREATE TRIGGER DisparadorAuditoriaProductos
ON Productos
AFTER INSERT, UPDATE, DELETE
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @Operacion NVARCHAR(10);
    DECLARE @RegistroID INT;
    DECLARE @Usuario NVARCHAR(50);

    IF EXISTS (SELECT * FROM inserted) AND EXISTS (SELECT * FROM deleted)
    BEGIN
        SET @Operacion = 'UPDATE';
        SELECT @RegistroID = ProductoID FROM inserted;
    END
    ELSE IF EXISTS (SELECT * FROM inserted)
    BEGIN
        SET @Operacion = 'INSERT';
        SELECT @RegistroID = ProductoID FROM inserted;
    END
    ELSE IF EXISTS (SELECT * FROM deleted)
    BEGIN
        SET @Operacion = 'DELETE';
        SELECT @RegistroID = ProductoID FROM deleted;
    END

    SET @Usuario = SYSTEM_USER; -- Esto asume que el nombre de usuario es el usuario del sistema ejecutando la operaci�n
    INSERT INTO AuditoriaCRUD (TipoOperacion, Tabla, RegistroID, Usuario, Fecha)
    VALUES (@Operacion, 'Productos', @RegistroID, @Usuario, GETDATE());
END


SELECT * FROM Clientes
SELECT * FROM Productos
SELECT * FROM AuditoriaCRUD
SELECT * FROM SesionesClientes
SELECT * FROM Pedidos
SELECT * FROM Ventas

SELECT * FROM PedidosCancelados



CREATE VIEW VistaClientesConPedidosActivos AS
SELECT 
    c.ClienteID,
    c.Nombre + ' ' + c.Apellido AS Cliente,
    p.PedidoID,
    pr.Nombre AS Producto,
    p.Cantidad,
    p.FechaCompra
FROM 
    Clientes c
    JOIN Pedidos p ON c.ClienteID = p.ClienteID
    JOIN Productos pr ON p.ProductoID = pr.ProductoID
WHERE 
    p.PedidoID NOT IN (SELECT PedidoID FROM PedidosCancelados);


CREATE VIEW VistaClientesConPedidosCancelados AS
SELECT 
    c.ClienteID,
    c.Nombre + ' ' + c.Apellido AS Cliente,
    pc.PedidoID,
    pr.Nombre AS Producto,
    pc.Cantidad,
    pc.FechaCancelacion
FROM 
    Clientes c
    JOIN PedidosCancelados pc ON c.ClienteID = pc.ClienteID
    JOIN Productos pr ON pc.ProductoID = pr.ProductoID;


CREATE VIEW VistaVentasRealizadas AS
SELECT 
    v.VentaID,
    v.PedidoID,
    c.Nombre + ' ' + c.Apellido AS Cliente,
    pr.Nombre AS Producto,
    v.Cantidad,
    v.FechaCompra
FROM 
    Ventas v
    JOIN Pedidos p ON v.PedidoID = p.PedidoID
    JOIN Clientes c ON p.ClienteID = c.ClienteID
    JOIN Productos pr ON v.ProductoID = pr.ProductoID;

