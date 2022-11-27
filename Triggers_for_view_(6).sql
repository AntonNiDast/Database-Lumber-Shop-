--Триггер: позволяет добавить материал соответствующий данному представлению.
CREATE OR REPLACE TRIGGER insert_view
INSTEAD OF INSERT ON materials_providers
DECLARE
provider_id INTEGER;
BEGIN
    BEGIN
        SELECT ID INTO provider_id
        FROM providers
        WHERE nameComp = :new.nameComp;

        EXCEPTION
        WHEN NO_DATA_FOUND THEN
            provider_id := NULL;
    END;

    IF provider_id IS NULL 
    THEN
        RAISE_APPLICATION_ERROR(
            num => -20009,
            msg => 'Такого поставщика не существует. Добавьте его в таблицу providers или выберете другого поставщика.');
    ELSE
        INSERT INTO materials(nameMat, quantityMat, providerID)
        VALUES (:new.nameMat, :new.quantityMat, provider_id);
    END IF;
END insert_view;

--Триггер: позволяет изменить материал соответствующий данному представлению.
CREATE OR REPLACE TRIGGER update_view
INSTEAD OF UPDATE ON materials_providers
DECLARE
provider_id_new INTEGER;
provider_id_old INTEGER;
material_id INTEGER;
BEGIN

    BEGIN
        SELECT ID INTO provider_id_new
        FROM providers
        WHERE nameComp = :new.nameComp;

        EXCEPTION
        WHEN NO_DATA_FOUND THEN
            provider_id_new := NULL;
    END;
    BEGIN
    SELECT ID INTO provider_id_old
    FROM providers
    WHERE nameComp = :old.nameComp;
        EXCEPTION
        WHEN NO_DATA_FOUND THEN
            provider_id_old := NULL;
    END;
    SELECT ID INTO material_id
    FROM materials
    WHERE nameMat = :old.nameMat AND quantityMat = :old.quantityMat;
    IF provider_id_new IS NULL 
    THEN
        update providers
        set nameComp = :new.nameComp
        where nameComp =:old.namecomp;
        UPDATE materials
        SET nameMat = :new.nameMat, 
            quantityMat = :new.quantityMat
        WHERE ID = material_id;
    ELSE
        UPDATE materials
        SET nameMat = :new.nameMat, 
            quantityMat = :new.quantityMat,
            providerID = provider_id_new
        WHERE ID = material_id;
    END IF;
END update_view;

