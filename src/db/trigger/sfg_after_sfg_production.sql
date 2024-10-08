
-- Function for INSERT trigger
CREATE OR REPLACE FUNCTION zipper.sfg_after_sfg_production_insert_function() 
RETURNS TRIGGER AS $$
DECLARE item_name TEXT;
BEGIN
    SELECT vodf.item_name INTO item_name 
    FROM zipper.sfg sfg
    LEFT JOIN zipper.order_entry oe ON oe.uuid = sfg.order_entry_uuid
    LEFT JOIN zipper.v_order_details_full vodf ON oe.order_description_uuid = vodf.order_description_uuid
    WHERE sfg.uuid = NEW.sfg_uuid;

    IF lower(item_name) = 'metal' THEN
        UPDATE zipper.sfg
        SET 
            od.metal_teeth_molding = od.metal_teeth_molding - 
                CASE 
                    WHEN NEW.section = 'teeth_molding' THEN NEW.production_quantity_in_kg + NEW.wastage 
                    ELSE 0
                END,
            teeth_molding_prod = teeth_molding_prod + 
                CASE 
                    WHEN NEW.section = 'teeth_molding' THEN NEW.production_quantity 
                    ELSE 
                        CASE
                            WHEN NEW.production_quantity_in_kg = 0 THEN NEW.production_quantity + NEW.wastage 
                            ELSE NEW.production_quantity_in_kg + NEW.wastage 
                        END 
                END,
            finishing_stock = finishing_stock - 
                CASE 
                    WHEN NEW.section = 'finishing' THEN NEW.production_quantity_in_kg + NEW.wastage 
                    ELSE 
                        CASE
                            WHEN NEW.production_quantity_in_kg = 0 THEN NEW.production_quantity + NEW.wastage 
                            ELSE NEW.production_quantity_in_kg + NEW.wastage 
                        END 
                END,
            finishing_prod = finishing_prod +
                CASE 
                    WHEN NEW.section = 'finishing' 
                    THEN NEW.production_quantity 
                    ELSE 
                       0
                END
        FROM zipper.order_entry oe
        LEFT JOIN zipper.order_description od ON od.uuid = oe.order_description_uuid
        WHERE sfg.uuid = NEW.sfg_uuid AND oe.uuid = sfg.order_entry_uuid;
    END IF;

    IF  lower(item_name) = 'vislon' THEN
        UPDATE zipper.sfg
        SET 
            od.vislon_teeth_molding = od.vislon_teeth_molding - 
                CASE 
                    WHEN NEW.section = 'teeth_molding' THEN 
                    CASE
                            WHEN NEW.production_quantity_in_kg = 0 THEN NEW.production_quantity + NEW.wastage 
                            ELSE NEW.production_quantity_in_kg + NEW.wastage 
                        END
                    ELSE 
                        0
                END,
            teeth_molding_prod = teeth_molding_prod + 
                CASE 
                    WHEN NEW.section = 'teeth_molding' THEN NEW.production_quantity 
                    ELSE 
                        CASE
                            WHEN NEW.production_quantity_in_kg = 0 THEN NEW.production_quantity 
                            ELSE NEW.production_quantity_in_kg 
                        END 
                END,
            finishing_stock = finishing_stock - 
                CASE 
                    WHEN NEW.section = 'finishing' THEN NEW.production_quantity_in_kg + NEW.wastage 
                    ELSE 
                        CASE
                            WHEN NEW.production_quantity_in_kg = 0 THEN NEW.production_quantity + NEW.wastage 
                            ELSE NEW.production_quantity_in_kg + NEW.wastage 
                        END 
                END,
            finishing_prod = finishing_prod +
                CASE 
                    WHEN NEW.section = 'finishing' 
                    THEN NEW.production_quantity 
                    ELSE 
                       0
                END
        FROM zipper.order_entry oe
        LEFT JOIN zipper.order_description od ON od.uuid = oe.order_description_uuid
        WHERE sfg.uuid = NEW.sfg_uuid AND oe.uuid = sfg.order_entry_uuid;
    END IF;

    IF lower(item_name) = 'nylon_plastic' THEN
        UPDATE zipper.sfg
        SET 
            od.nylon_plastic_finishing = od.nylon_plastic_finishing - 
                CASE 
                    WHEN NEW.section = 'finishing' THEN NEW.production_quantity_in_kg + NEW.wastage 
                    ELSE 
                        CASE
                            WHEN NEW.production_quantity_in_kg = 0 THEN NEW.production_quantity + NEW.wastage 
                            ELSE NEW.production_quantity_in_kg + NEW.wastage 
                        END 
                END,
            finishing_prod = finishing_prod +
                CASE 
                    WHEN NEW.section = 'finishing' 
                    THEN NEW.production_quantity 
                    ELSE 
                       0
                END
        FROM zipper.order_entry oe
        LEFT JOIN zipper.order_description od ON od.uuid = oe.order_description_uuid
        WHERE sfg.uuid = NEW.sfg_uuid AND oe.uuid = sfg.order_entry_uuid;
    END IF;

    IF lower(item_name) = 'nylon_metallic' THEN
        UPDATE zipper.sfg
        SET 
            od.nylon_metallic_finishing = od.nylon_metallic_finishing - 
                CASE 
                    WHEN NEW.section = 'finishing' THEN NEW.production_quantity_in_kg + NEW.wastage 
                    ELSE 
                        CASE
                            WHEN NEW.production_quantity_in_kg = 0 THEN NEW.production_quantity + NEW.wastage 
                            ELSE NEW.production_quantity_in_kg + NEW.wastage 
                        END 
                END,
            finishing_prod = finishing_prod +
                CASE 
                    WHEN NEW.section = 'finishing' 
                    THEN NEW.production_quantity 
                    ELSE 
                       0
                END
        FROM zipper.order_entry oe
        LEFT JOIN zipper.order_description od ON od.uuid = oe.order_description_uuid
        WHERE sfg.uuid = NEW.sfg_uuid AND oe.uuid = sfg.order_entry_uuid;
    END IF;

    UPDATE zipper.sfg
    SET 
        teeth_coloring_stock = teeth_coloring_stock - 
            CASE 
                WHEN NEW.section = 'teeth_coloring' THEN 
                    CASE 
                        WHEN NEW.production_quantity_in_kg = 0 THEN NEW.production_quantity + NEW.wastage 
                        ELSE NEW.production_quantity_in_kg + NEW.wastage 
                    END 
                ELSE 0 
            END,
        dying_and_iron_prod = dying_and_iron_prod + 
            CASE 
                WHEN NEW.section = 'dying_and_iron' THEN 
                     NEW.production_quantity 
                ELSE 0 
            END,
        teeth_coloring_prod = teeth_coloring_prod + 
            CASE 
                WHEN NEW.section = 'teeth_coloring' THEN 
                     NEW.production_quantity 
                ELSE 0 
            END,
        coloring_prod = coloring_prod + 
            CASE 
                WHEN NEW.section = 'coloring' THEN 
                     NEW.production_quantity
                ELSE 0 
            END
    FROM zipper.order_entry oe
    LEFT JOIN zipper.order_description od ON od.uuid = oe.order_description_uuid
    WHERE sfg.uuid = NEW.sfg_uuid AND oe.uuid = sfg.order_entry_uuid;

    -- New condition for updating slider stock
   UPDATE slider.stock SET
        coloring_prod = slider.stock.coloring_prod - 
        CASE WHEN NEW.section = 'finishing' THEN NEW.production_quantity ELSE 0 END
    FROM zipper.order_entry oe
    LEFT JOIN zipper.v_order_details_full vodf ON vodf.order_description_uuid = oe.order_description_uuid
    LEFT JOIN zipper.sfg ON zipper.sfg.order_entry_uuid = oe.uuid
    WHERE slider.stock.order_description_uuid = vodf.order_description_uuid 
        AND zipper.sfg.uuid = NEW.sfg_uuid;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger for INSERT
CREATE OR REPLACE TRIGGER sfg_after_sfg_production_insert_trigger
AFTER INSERT ON zipper.sfg_production
FOR EACH ROW
EXECUTE FUNCTION zipper.sfg_after_sfg_production_insert_function();



-- Function for UPDATE trigger
CREATE OR REPLACE FUNCTION zipper.sfg_after_sfg_production_update_function()
RETURNS TRIGGER AS $$
BEGIN
    IF lower(vodf.item_name) = 'metal' THEN
        UPDATE zipper.sfg
        SET 
            metal_teeth_molding = metal_teeth_molding - 
                CASE 
                    WHEN NEW.section = 'teeth_molding' THEN NEW.production_quantity_in_kg + NEW.wastage 
                    ELSE 0
                END,
            teeth_molding_prod = teeth_molding_prod + 
                CASE 
                    WHEN NEW.section = 'teeth_molding' THEN NEW.production_quantity 
                    ELSE 
                        CASE
                            WHEN NEW.production_quantity_in_kg = 0 THEN NEW.production_quantity + NEW.wastage 
                            ELSE NEW.production_quantity_in_kg + NEW.wastage 
                        END 
                END
        WHERE uuid = NEW.sfg_uuid;
    END IF;

    IF  lower(vodf.item_name) = 'vislon' THEN
        UPDATE zipper.sfg
        SET 
            finishing_stock = finishing_stock - 
                CASE 
                    WHEN NEW.section = 'finishing' THEN NEW.production_quantity_in_kg + NEW.wastage 
                    ELSE 
                        CASE
                            WHEN NEW.production_quantity_in_kg = 0 THEN NEW.production_quantity + NEW.wastage 
                            ELSE NEW.production_quantity_in_kg + NEW.wastage 
                        END 
                END,
            finishing_prod = finishing_prod + 
                CASE 
                    WHEN NEW.section = 'finishing' THEN NEW.production_quantity 
                    ELSE 
                        CASE
                            WHEN NEW.production_quantity_in_kg = 0 THEN NEW.production_quantity 
                            ELSE NEW.production_quantity_in_kg 
                        END 
                END
        WHERE uuid = NEW.sfg_uuid;
    END IF;

    IF lower(vodf.item_name) = 'nylon_plastic' THEN
        UPDATE zipper.sfg
        SET 
            nylon_plastic_finishing = nylon_plastic_finishing - 
                CASE 
                    WHEN NEW.section = 'finishing' THEN NEW.production_quantity_in_kg + NEW.wastage 
                    ELSE 
                        CASE
                            WHEN NEW.production_quantity_in_kg = 0 THEN NEW.production_quantity + NEW.wastage 
                            ELSE NEW.production_quantity_in_kg + NEW.wastage 
                        END 
                END
        WHERE uuid = NEW.sfg_uuid;
    END IF;

    IF lower(vodf.item_name) = 'nylon_metallic' THEN
        UPDATE zipper.sfg
        SET 
            nylon_metallic_finishing = nylon_metallic_finishing - 
                CASE 
                    WHEN NEW.section = 'finishing' THEN NEW.production_quantity_in_kg + NEW.wastage 
                    ELSE 
                        CASE
                            WHEN NEW.production_quantity_in_kg = 0 THEN NEW.production_quantity + NEW.wastage 
                            ELSE NEW.production_quantity_in_kg + NEW.wastage 
                        END 
                END
        WHERE uuid = NEW.sfg_uuid;
    END IF;

    UPDATE zipper.sfg

    SET 
        teeth_coloring_stock = teeth_coloring_stock - 
            CASE 
                WHEN NEW.section = 'teeth_coloring' THEN 
                    CASE 
                        WHEN NEW.production_quantity_in_kg = 0 THEN NEW.production_quantity + NEW.wastage 
                        ELSE NEW.production_quantity_in_kg + NEW.wastage 
                    END 
                ELSE 0 
            END,
        dying_and_iron_prod = dying_and_iron_prod + 
            CASE 
                WHEN NEW.section = 'dying_and_iron' THEN 
                    CASE 
                        WHEN NEW.production_quantity_in_kg = 0 THEN NEW.production_quantity 
                        ELSE NEW.production_quantity_in_kg 
                    END 
                ELSE 0 
            END,
        teeth_coloring_prod = teeth_coloring_prod + 
            CASE 
                WHEN NEW.section = 'teeth_coloring' THEN 
                    CASE 
                        WHEN NEW.production_quantity_in_kg = 0 THEN NEW.production_quantity 
                        ELSE NEW.production_quantity_in_kg 
                    END 
                ELSE 0 
            END,
        coloring_prod = coloring_prod + 
            CASE 
                WHEN NEW.section = 'coloring' THEN 
                    CASE 
                        WHEN NEW.production_quantity_in_kg = 0 THEN NEW.production_quantity 
                        ELSE NEW.production_quantity_in_kg 
                    END 
                ELSE 0 
            END
    -- WHERE uuid = NEW.sfg_uuid;
    FROM zipper.order_entry oe
    LEFT JOIN zipper.v_order_details_full vodf ON vodf.order_description_uuid = oe.order_description_uuid
    WHERE zipper.sfg.order_entry_uuid = oe.uuid AND zipper.sfg.uuid = NEW.sfg_uuid;

    -- New condition for updating slider stock
    UPDATE slider.stock SET
        coloring_prod = slider.stock.coloring_prod - 
        CASE WHEN NEW.section = 'finishing' THEN NEW.production_quantity ELSE 0 END
    FROM zipper.order_entry oe
    LEFT JOIN zipper.v_order_details_full vodf ON vodf.order_description_uuid = oe.order_description_uuid
    LEFT JOIN zipper.sfg ON zipper.sfg.order_entry_uuid = oe.uuid
    WHERE slider.stock.order_description_uuid = vodf.order_description_uuid 
        AND zipper.sfg.uuid = NEW.sfg_uuid;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger for UPDATE
CREATE OR REPLACE TRIGGER sfg_after_sfg_production_update_trigger
AFTER UPDATE ON zipper.sfg_production
FOR EACH ROW
EXECUTE FUNCTION zipper.sfg_after_sfg_production_update_function();

-- Function for DELETE trigger
CREATE OR REPLACE FUNCTION zipper.sfg_after_sfg_production_delete_function() 
RETURNS TRIGGER AS $$
BEGIN
    IF lower(vodf.item_name) = 'metal' THEN
        UPDATE zipper.sfg
        SET 
            metal_teeth_molding = metal_teeth_molding + 
                CASE 
                    WHEN OLD.section = 'teeth_molding' THEN OLD.production_quantity_in_kg + OLD.wastage 
                    ELSE 0
                END,
            teeth_molding_prod = teeth_molding_prod - 
                CASE 
                    WHEN OLD.section = 'teeth_molding' THEN OLD.production_quantity 
                    ELSE 
                        CASE
                            WHEN OLD.production_quantity_in_kg = 0 THEN OLD.production_quantity + OLD.wastage 
                            ELSE OLD.production_quantity_in_kg + OLD.wastage 
                        END 
                END,
            finishing_stock = finishing_stock + 
                CASE 
                    WHEN OLD.section = 'finishing' THEN OLD.production_quantity_in_kg + OLD.wastage 
                    ELSE 
                        CASE
                            WHEN OLD.production_quantity_in_kg = 0 THEN OLD.production_quantity + OLD.wastage 
                            ELSE OLD.production_quantity_in_kg + OLD.wastage 
                        END 
                END,
            finishing_prod = finishing_prod -
                CASE 
                    WHEN OLD.section = 'finishing' 
                    THEN OLD.production_quantity 
                    ELSE 
                       0
                END
        WHERE uuid = OLD.sfg_uuid;
    END IF;

    IF  lower(vodf.item_name) = 'vislon' THEN
        UPDATE zipper.sfg
        SET 
            vislon_teeth_molding = vislon_teeth_molding + 
                CASE 
                    WHEN OLD.section = 'teeth_molding' THEN 
                    CASE
                            WHEN OLD.production_quantity_in_kg = 0 THEN OLD.production_quantity + OLD.wastage 
                            ELSE OLD.production_quantity_in_kg + OLD.wastage 
                        END
                    ELSE 
                        0
                END,
            teeth_molding_prod = teeth_molding_prod - 
                CASE 
                    WHEN OLD.section = 'teeth_molding' THEN OLD.production_quantity 
                    ELSE 
                        CASE
                            WHEN OLD.production_quantity_in_kg = 0 THEN OLD.production_quantity 
                            ELSE OLD.production_quantity_in_kg 
                        END 
                END,
            finishing_stock = finishing_stock + 
                CASE 
                    WHEN OLD.section = 'finishing' THEN OLD.production_quantity_in_kg + OLD.wastage 
                    ELSE 
                        CASE
                            WHEN OLD.production_quantity_in_kg = 0 THEN OLD.production_quantity + OLD.wastage 
                            ELSE OLD.production_quantity_in_kg + OLD.wastage 
                        END 
                END,
            finishing_prod = finishing_prod -
                CASE 
                    WHEN OLD.section = 'finishing' 
                    THEN OLD.production_quantity 
                    ELSE 
                       0
                END
        WHERE uuid = OLD.sfg_uuid;
    END IF;

    IF lower(vodf.item_name) = 'nylon_plastic' THEN
        UPDATE zipper.sfg
        SET 
            nylon_plastic_finishing = nylon_plastic_finishing + 
                CASE 
                    WHEN OLD.section = 'finishing' THEN OLD.production_quantity_in_kg + OLD.wastage 
                    ELSE 
                        CASE
                            WHEN OLD.production_quantity_in_kg = 0 THEN OLD.production_quantity + OLD.wastage 
                            ELSE OLD.production_quantity_in_kg + OLD.wastage 
                        END 
                END,
            finishing_prod = finishing_prod -
                CASE 
                    WHEN OLD.section = 'finishing' 
                    THEN OLD.production_quantity 
                    ELSE 
                       0
                END
        WHERE uuid = OLD.sfg_uuid;
    END IF;

    IF lower(vodf.item_name) = 'nylon_metallic' THEN
        UPDATE zipper.sfg
        SET 
            nylon_metallic_finishing = nylon_metallic_finishing + 
                CASE 
                    WHEN OLD.section = 'finishing' THEN OLD.production_quantity_in_kg + OLD.wastage 
                    ELSE 
                        CASE
                            WHEN OLD.production_quantity_in_kg = 0 THEN OLD.production_quantity + OLD.wastage 
                            ELSE OLD.production_quantity_in_kg + OLD.wastage 
                        END 
                END,
            finishing_prod = finishing_prod -
                CASE 
                    WHEN OLD.section = 'finishing' 
                    THEN OLD.production_quantity 
                    ELSE 
                       0
                END
        WHERE uuid = OLD.sfg_uuid;
    END IF;

    UPDATE zipper.sfg
    SET 
        teeth_coloring_stock = teeth_coloring_stock + 
            CASE 
                WHEN OLD.section = 'teeth_coloring' THEN 
                    CASE 
                        WHEN OLD.production_quantity_in_kg = 0 THEN OLD.production_quantity + OLD.wastage 
                        ELSE OLD.production_quantity_in_kg + OLD.wastage 
                    END 
                ELSE 0 
            END,
        dying_and_iron_prod = dying_and_iron_prod - 
            CASE 
                WHEN OLD.section = 'dying_and_iron' THEN 
                     OLD.production_quantity 
                ELSE 0 
            END,
        teeth_coloring_prod = teeth_coloring_prod - 
            CASE 
                WHEN OLD.section = 'teeth_coloring' THEN 
                     OLD.production_quantity 
                ELSE 0 
            END,
        coloring_prod = coloring_prod - 
            CASE 
                WHEN OLD.section = 'coloring' THEN 
                     OLD.production_quantity
                ELSE 0 
            END
    WHERE uuid = OLD.sfg_uuid;

    -- New condition for updating slider stock
   UPDATE slider.stock SET
        coloring_prod = slider.stock.coloring_prod + 
        CASE WHEN OLD.section = 'finishing' THEN OLD.production_quantity ELSE 0 END
    FROM zipper.order_entry oe
    LEFT JOIN zipper.v_order_details_full vodf ON vodf.order_description_uuid = oe.order_description_uuid
    LEFT JOIN zipper.sfg ON zipper.sfg.order_entry_uuid = oe.uuid
    WHERE slider.stock.order_description_uuid = vodf.order_description_uuid 
        AND zipper.sfg.uuid = OLD.sfg_uuid;

    RETURN OLD;
END;
$$ LANGUAGE plpgsql;

-- Trigger for DELETE
CREATE OR REPLACE TRIGGER sfg_after_sfg_production_delete_trigger
AFTER DELETE ON zipper.sfg_production
FOR EACH ROW
EXECUTE FUNCTION zipper.sfg_after_sfg_production_delete_function();

