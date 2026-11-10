USE Universidade;
GO

CREATE PROCEDURE sp_CadastraNotas
(
    @MATRICULA INT,
    @CURSO CHAR(3),
    @MATERIA CHAR(3),
    @PERLETIVO INT,
    @NOTA FLOAT,
    @FALTA INT,
    @BIMESTRE INT
)
AS
BEGIN
    DECLARE @CARGAHORA INT,
            @MEDIA FLOAT,
            @TOTALFALTAS INT,
            @FREQUENCIA FLOAT,
            @RESULTADO VARCHAR(20);

    IF NOT EXISTS (SELECT 1 FROM MATRICULA
                   WHERE MATRICULA = @MATRICULA AND CURSO = @CURSO
                     AND MATERIA = @MATERIA AND PERLETIVO = @PERLETIVO)
    BEGIN
        RAISERROR('Aluno nao matriculado nessa materia.', 16, 1);
        RETURN;
    END

    IF @NOTA < 0 OR @NOTA > 10
    BEGIN
        RAISERROR('A nota deve ser entre 0 e 10.', 16, 1);
        RETURN;
    END

    IF @BIMESTRE NOT IN (1, 2, 3, 4)
    BEGIN
        RAISERROR('Bimestre invalido (use 1, 2, 3 ou 4).', 16, 1);
        RETURN;
    END

    IF @BIMESTRE = 1
    BEGIN
        UPDATE MATRICULA
        SET N1 = @NOTA, F1 = @FALTA,
            TOTALPONTOS = @NOTA,
            TOTALFALTAS = @FALTA,
            MEDIA = @NOTA
        WHERE MATRICULA = @MATRICULA AND CURSO = @CURSO
          AND MATERIA = @MATERIA AND PERLETIVO = @PERLETIVO;
    END
    ELSE IF @BIMESTRE = 2
    BEGIN
        UPDATE MATRICULA
        SET N2 = @NOTA, F2 = @FALTA,
            TOTALPONTOS = @NOTA + N1,
            TOTALFALTAS = @FALTA + F1,
            MEDIA = (@NOTA + N1) / 2
        WHERE MATRICULA = @MATRICULA AND CURSO = @CURSO
          AND MATERIA = @MATERIA AND PERLETIVO = @PERLETIVO;
    END
    ELSE IF @BIMESTRE = 3
    BEGIN
        UPDATE MATRICULA
        SET N3 = @NOTA, F3 = @FALTA,
            TOTALPONTOS = @NOTA + N1 + N2,
            TOTALFALTAS = @FALTA + F1 + F2,
            MEDIA = (@NOTA + N1 + N2) / 3
        WHERE MATRICULA = @MATRICULA AND CURSO = @CURSO
          AND MATERIA = @MATERIA AND PERLETIVO = @PERLETIVO;
    END
    ELSE IF @BIMESTRE = 4
    BEGIN
        UPDATE MATRICULA
        SET N4 = @NOTA, F4 = @FALTA,
            TOTALPONTOS = @NOTA + N1 + N2 + N3,
            TOTALFALTAS = @FALTA + F1 + F2 + F3,
            MEDIA = (@NOTA + N1 + N2 + N3) / 4
        WHERE MATRICULA = @MATRICULA AND CURSO = @CURSO
          AND MATERIA = @MATERIA AND PERLETIVO = @PERLETIVO;

        SELECT @CARGAHORA = CARGAHORARIA
        FROM MATERIAS
        WHERE SIGLA = @MATERIA AND CURSO = @CURSO;

        SELECT @MEDIA = MEDIA, @TOTALFALTAS = TOTALFALTAS
        FROM MATRICULA
        WHERE MATRICULA = @MATRICULA AND CURSO = @CURSO
          AND MATERIA = @MATERIA AND PERLETIVO = @PERLETIVO;

        SET @FREQUENCIA = (@CARGAHORA - @TOTALFALTAS) * 100.0 / @CARGAHORA;

        IF @FREQUENCIA < 75
            SET @RESULTADO = 'REPROVADO POR FALTA';
        ELSE IF @MEDIA >= 7
            SET @RESULTADO = 'APROVADO';
        ELSE IF @MEDIA >= 4
            SET @RESULTADO = 'EXAME';
        ELSE
            SET @RESULTADO = 'REPROVADO';

        UPDATE MATRICULA
        SET PERCFREQ = @FREQUENCIA,
            RESULTADO = @RESULTADO,
            MEDIAFINAL = CASE WHEN @RESULTADO = 'EXAME' THEN NULL ELSE @MEDIA END
        WHERE MATRICULA = @MATRICULA AND CURSO = @CURSO
          AND MATERIA = @MATERIA AND PERLETIVO = @PERLETIVO;
    END

    SELECT * FROM MATRICULA
    WHERE MATRICULA = @MATRICULA AND CURSO = @CURSO
      AND MATERIA = @MATERIA AND PERLETIVO = @PERLETIVO;
END
GO


EXEC sp_CadastraNotas 1, 'ENG', 'BDA', 2025, 8, 2, 1;
EXEC sp_CadastraNotas 1, 'ENG', 'BDA', 2025, 7, 0, 2;
EXEC sp_CadastraNotas 1, 'ENG', 'BDA', 2025, 9, 1, 3;
EXEC sp_CadastraNotas 1, 'ENG', 'BDA', 2025, 8, 0, 4;

EXEC sp_CadastraNotas 2, 'ENG', 'BDA', 2025, 5, 1, 1;
EXEC sp_CadastraNotas 2, 'ENG', 'BDA', 2025, 6, 1, 2;
EXEC sp_CadastraNotas 2, 'ENG', 'BDA', 2025, 5, 0, 3;
EXEC sp_CadastraNotas 2, 'ENG', 'BDA', 2025, 6, 0, 4;

EXEC sp_CadastraNotas 3, 'ENG', 'BDA', 2025, 2, 0, 1;
EXEC sp_CadastraNotas 3, 'ENG', 'BDA', 2025, 3, 0, 2;
EXEC sp_CadastraNotas 3, 'ENG', 'BDA', 2025, 2, 0, 3;
EXEC sp_CadastraNotas 3, 'ENG', 'BDA', 2025, 3, 0, 4;

EXEC sp_CadastraNotas 4, 'ENG', 'BDA', 2025, 9, 10, 1;
EXEC sp_CadastraNotas 4, 'ENG', 'BDA', 2025, 9, 10, 2;
EXEC sp_CadastraNotas 4, 'ENG', 'BDA', 2025, 9, 10, 3;
EXEC sp_CadastraNotas 4, 'ENG', 'BDA', 2025, 9, 10, 4;
GO

SELECT MATRICULA, MATERIA, MEDIA, TOTALFALTAS, PERCFREQ, RESULTADO
FROM MATRICULA
WHERE MATERIA = 'BDA'
ORDER BY MATRICULA;