CREATE OR REPLACE PACKAGE ClientesPkg AS
    PROCEDURE InsertOrUpdateCliente(p_correo IN VARCHAR2, p_nombre IN VARCHAR2, p_telefono IN VARCHAR2);
    PROCEDURE modificar_cliente(p_correo IN VARCHAR2, p_nombre IN VARCHAR2, p_telefono IN VARCHAR2);
    PROCEDURE eliminar_cliente(p_correo IN VARCHAR2);
    PROCEDURE eliminar_todos_clientes;
    FUNCTION listar_cliente(p_correo IN VARCHAR2) RETURN SYS_REFCURSOR;
    FUNCTION listar_clientes RETURN SYS_REFCURSOR;
    FUNCTION listar_reservas_cliente(p_correo IN VARCHAR2) RETURN SYS_REFCURSOR;
END ClientesPkg;