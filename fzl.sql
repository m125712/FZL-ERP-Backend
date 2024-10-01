PGDMP  7                	    |            fzl    16.4    16.4 �   D           0    0    ENCODING    ENCODING        SET client_encoding = 'UTF8';
                      false            E           0    0 
   STDSTRINGS 
   STDSTRINGS     (   SET standard_conforming_strings = 'on';
                      false            F           0    0 
   SEARCHPATH 
   SEARCHPATH     8   SELECT pg_catalog.set_config('search_path', '', false);
                      false            G           1262    17923    fzl    DATABASE     ~   CREATE DATABASE fzl WITH TEMPLATE = template0 ENCODING = 'UTF8' LOCALE_PROVIDER = libc LOCALE = 'English_United States.1252';
    DROP DATABASE fzl;
                postgres    false                        2615    17924 
   commercial    SCHEMA        CREATE SCHEMA commercial;
    DROP SCHEMA commercial;
                postgres    false                        2615    17925    delivery    SCHEMA        CREATE SCHEMA delivery;
    DROP SCHEMA delivery;
                postgres    false                        2615    17926    drizzle    SCHEMA        CREATE SCHEMA drizzle;
    DROP SCHEMA drizzle;
                postgres    false            	            2615    17927    hr    SCHEMA        CREATE SCHEMA hr;
    DROP SCHEMA hr;
                postgres    false            
            2615    17928    lab_dip    SCHEMA        CREATE SCHEMA lab_dip;
    DROP SCHEMA lab_dip;
                postgres    false                        2615    17929    material    SCHEMA        CREATE SCHEMA material;
    DROP SCHEMA material;
                postgres    false                        2615    17930    purchase    SCHEMA        CREATE SCHEMA purchase;
    DROP SCHEMA purchase;
                postgres    false                        2615    17931    slider    SCHEMA        CREATE SCHEMA slider;
    DROP SCHEMA slider;
                postgres    false                        2615    17932    thread    SCHEMA        CREATE SCHEMA thread;
    DROP SCHEMA thread;
                postgres    false                        2615    17933    zipper    SCHEMA        CREATE SCHEMA zipper;
    DROP SCHEMA zipper;
                postgres    false                       1247    17935    batch_status    TYPE     m   CREATE TYPE zipper.batch_status AS ENUM (
    'pending',
    'completed',
    'rejected',
    'cancelled'
);
    DROP TYPE zipper.batch_status;
       zipper          postgres    false    15            �           1247    139369    print_in_enum    TYPE     `   CREATE TYPE zipper.print_in_enum AS ENUM (
    'portrait',
    'landscape',
    'break_down'
);
     DROP TYPE zipper.print_in_enum;
       zipper          postgres    false    15            
           1247    17942    slider_starting_section_enum    TYPE     �   CREATE TYPE zipper.slider_starting_section_enum AS ENUM (
    'die_casting',
    'slider_assembly',
    'coloring',
    '---'
);
 /   DROP TYPE zipper.slider_starting_section_enum;
       zipper          postgres    false    15                       1247    17952    swatch_status_enum    TYPE     a   CREATE TYPE zipper.swatch_status_enum AS ENUM (
    'pending',
    'approved',
    'rejected'
);
 %   DROP TYPE zipper.swatch_status_enum;
       zipper          postgres    false    15            v           1255    17959 /   sfg_after_commercial_pi_entry_delete_function()    FUNCTION     (  CREATE FUNCTION commercial.sfg_after_commercial_pi_entry_delete_function() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    UPDATE zipper.sfg SET
        pi = pi - OLD.pi_cash_quantity
    WHERE uuid = OLD.sfg_uuid;

    UPDATE thread.order_entry SET
        pi = pi - OLD.pi_cash_quantity
    WHERE uuid = OLD.thread_order_entry_uuid;

    -- UPDATE pi_cash table and remove the particular order_info_uuids from the array if there is no sfg_uuid in pi_cash_entry
    IF OLD.sfg_uuid IS NOT NULL THEN 
    UPDATE commercial.pi_cash
    SET
        order_info_uuids = COALESCE(
            (
                SELECT jsonb_agg(elem)
                FROM (
                    SELECT elem
                    FROM jsonb_array_elements_text(order_info_uuids::jsonb) elem
                    WHERE elem != (
                        SELECT DISTINCT vod.order_info_uuid::text 
                        FROM zipper.v_order_details vod 
                        WHERE vod.order_description_uuid = (
                            SELECT oe.order_description_uuid 
                            FROM zipper.order_entry oe 
                            WHERE oe.uuid = OLD.sfg_uuid
                        )
                    )
                ) subquery
            ), '[]'::jsonb
        )
    WHERE EXISTS (
        -- Check existence after the deletion is complete
        SELECT 1
        FROM zipper.sfg sfg
        LEFT JOIN zipper.order_entry oe ON sfg.order_entry_uuid = oe.uuid
        LEFT JOIN zipper.v_order_details vod ON oe.order_description_uuid = vod.order_description_uuid
        WHERE sfg.uuid = OLD.sfg_uuid
    );
    END IF;

    -- If the pi_cash_entry is deleted, then delete the pi_cash_entry from pi_cash table for thread
    IF OLD.thread_order_entry_uuid IS NOT NULL THEN
    UPDATE commercial.pi_cash
    SET
        thread_order_info_uuids = COALESCE(
            (
                SELECT jsonb_agg(elem)
                FROM (
                    SELECT elem
                    FROM jsonb_array_elements_text(thread_order_info_uuids::jsonb) elem
                    WHERE elem != (
                        SELECT DISTINCT toi.uuid::text 
                        FROM thread.order_info toi 
                        WHERE toi.uuid = (
                            SELECT toe.order_info_uuid 
                            FROM thread.order_entry toe 
                            WHERE toe.uuid = OLD.thread_order_entry_uuid
                        )
                    )
                ) subquery
            ), '[]'::jsonb
        )
    WHERE EXISTS (
        -- Check existence after the deletion is complete
        SELECT 1
        FROM thread.order_entry toe
        LEFT JOIN thread.order_info toi ON toe.order_info_uuid = toi.uuid
        WHERE toe.uuid = OLD.thread_order_entry_uuid
    );
    END IF;

    RETURN OLD;
END;
$$;
 J   DROP FUNCTION commercial.sfg_after_commercial_pi_entry_delete_function();
    
   commercial          postgres    false    6            p           1255    17960 /   sfg_after_commercial_pi_entry_insert_function()    FUNCTION     r  CREATE FUNCTION commercial.sfg_after_commercial_pi_entry_insert_function() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    UPDATE zipper.sfg SET
        pi = pi + NEW.pi_cash_quantity
    WHERE uuid = NEW.sfg_uuid;

    UPDATE thread.order_entry SET
        pi = pi + NEW.pi_cash_quantity
    WHERE uuid = NEW.thread_order_entry_uuid;

    RETURN NEW;
END;
$$;
 J   DROP FUNCTION commercial.sfg_after_commercial_pi_entry_insert_function();
    
   commercial          postgres    false    6            �           1255    17961 /   sfg_after_commercial_pi_entry_update_function()    FUNCTION     �  CREATE FUNCTION commercial.sfg_after_commercial_pi_entry_update_function() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    UPDATE zipper.sfg SET
        pi = pi + NEW.pi_cash_quantity - OLD.pi_cash_quantity
    WHERE uuid = NEW.sfg_uuid;

    UPDATE thread.order_entry SET
        pi = pi + NEW.pi_cash_quantity - OLD.pi_cash_quantity
    WHERE uuid = NEW.thread_order_entry_uuid;

    RETURN NEW;
END;
$$;
 J   DROP FUNCTION commercial.sfg_after_commercial_pi_entry_update_function();
    
   commercial          postgres    false    6            m           1255    131152 2   packing_list_after_challan_entry_delete_function()    FUNCTION     +  CREATE FUNCTION delivery.packing_list_after_challan_entry_delete_function() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    -- Update delivery,packing_list
    UPDATE delivery.packing_list
    SET
        challan_uuid = NULL
    WHERE uuid = OLD.packing_list_uuid;
    RETURN OLD;
END;
$$;
 K   DROP FUNCTION delivery.packing_list_after_challan_entry_delete_function();
       delivery          postgres    false    7            [           1255    131151 2   packing_list_after_challan_entry_insert_function()    FUNCTION     7  CREATE FUNCTION delivery.packing_list_after_challan_entry_insert_function() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    -- Update delivery,packing_list
    UPDATE delivery.packing_list
    SET
        challan_uuid = NEW.challan_uuid
    WHERE uuid = NEW.packing_list_uuid;
    RETURN NEW;
END;
$$;
 K   DROP FUNCTION delivery.packing_list_after_challan_entry_insert_function();
       delivery          postgres    false    7            �           1255    131153 2   packing_list_after_challan_entry_update_function()    FUNCTION     7  CREATE FUNCTION delivery.packing_list_after_challan_entry_update_function() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    -- Update delivery,packing_list
    UPDATE delivery.packing_list
    SET
        challan_uuid = NEW.challan_uuid
    WHERE uuid = NEW.packing_list_uuid;
    RETURN NEW;
END;
$$;
 K   DROP FUNCTION delivery.packing_list_after_challan_entry_update_function();
       delivery          postgres    false    7            T           1255    131262 2   sfg_after_challan_receive_status_delete_function()    FUNCTION     �  CREATE FUNCTION delivery.sfg_after_challan_receive_status_delete_function() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    -- Update zipper,sfg
    UPDATE zipper.sfg
    SET
        warehouse = warehouse + CASE WHEN OLD.receive_status = 1 THEN OLD.quantity ELSE 0 END,
        delivered = delivered - CASE WHEN OLD.receive_status = 1 THEN OLD.quantity ELSE 0 END
    WHERE uuid = OLD.sfg_uuid;
    RETURN OLD;
END;
$$;
 K   DROP FUNCTION delivery.sfg_after_challan_receive_status_delete_function();
       delivery          postgres    false    7            f           1255    131261 2   sfg_after_challan_receive_status_insert_function()    FUNCTION     �  CREATE FUNCTION delivery.sfg_after_challan_receive_status_insert_function() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    -- Update zipper,sfg
    UPDATE zipper.sfg
    SET
        warehouse = warehouse - CASE WHEN NEW.receive_status = 1 THEN NEW.quantity ELSE 0 END,
        delivered = delivered + CASE WHEN NEW.receive_status = 1 THEN NEW.quantity ELSE 0 END
    WHERE uuid = NEW.sfg_uuid;
    RETURN NEW;
END;
$$;
 K   DROP FUNCTION delivery.sfg_after_challan_receive_status_insert_function();
       delivery          postgres    false    7            �           1255    131263 2   sfg_after_challan_receive_status_update_function()    FUNCTION     -  CREATE FUNCTION delivery.sfg_after_challan_receive_status_update_function() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    -- Update zipper,sfg
    UPDATE zipper.sfg
    SET
        warehouse = warehouse - CASE WHEN NEW.receive_status = 1 THEN NEW.quantity ELSE 0 END + CASE WHEN OLD.receive_status = 1 THEN OLD.quantity ELSE 0 END,
        delivered = delivered + CASE WHEN NEW.receive_status = 1 THEN NEW.quantity ELSE 0 END - CASE WHEN OLD.receive_status = 1 THEN OLD.quantity ELSE 0 END
    WHERE uuid = NEW.sfg_uuid;
    RETURN NEW;
END;
$$;
 K   DROP FUNCTION delivery.sfg_after_challan_receive_status_update_function();
       delivery          postgres    false    7            �           1255    131146 .   sfg_after_packing_list_entry_delete_function()    FUNCTION     Q  CREATE FUNCTION delivery.sfg_after_packing_list_entry_delete_function() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    -- Update zipper,sfg
    UPDATE zipper.sfg
    SET
        warehouse = warehouse - OLD.quantity,
        finishing_prod = finishing_prod + OLD.quantity
    WHERE uuid = OLD.sfg_uuid;
    RETURN OLD;
END;
$$;
 G   DROP FUNCTION delivery.sfg_after_packing_list_entry_delete_function();
       delivery          postgres    false    7            s           1255    131145 .   sfg_after_packing_list_entry_insert_function()    FUNCTION     Q  CREATE FUNCTION delivery.sfg_after_packing_list_entry_insert_function() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    -- Update zipper,sfg
    UPDATE zipper.sfg
    SET
        warehouse = warehouse + NEW.quantity,
        finishing_prod = finishing_prod - NEW.quantity
    WHERE uuid = NEW.sfg_uuid;
    RETURN NEW;
END;
$$;
 G   DROP FUNCTION delivery.sfg_after_packing_list_entry_insert_function();
       delivery          postgres    false    7            i           1255    131147 .   sfg_after_packing_list_entry_update_function()    FUNCTION     o  CREATE FUNCTION delivery.sfg_after_packing_list_entry_update_function() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    -- Update zipper,sfg
    UPDATE zipper.sfg
    SET
        warehouse = warehouse - OLD.quantity + NEW.quantity,
        finishing_prod = finishing_prod + OLD.quantity - NEW.quantity
    WHERE uuid = NEW.sfg_uuid;
    RETURN NEW;
END;
$$;
 G   DROP FUNCTION delivery.sfg_after_packing_list_entry_update_function();
       delivery          postgres    false    7            N           1255    17962 +   material_stock_after_material_info_delete()    FUNCTION     �   CREATE FUNCTION material.material_stock_after_material_info_delete() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    DELETE FROM material.stock
    WHERE material_uuid = OLD.uuid;
    RETURN OLD;
END;
$$;
 D   DROP FUNCTION material.material_stock_after_material_info_delete();
       material          postgres    false    11            {           1255    17963 +   material_stock_after_material_info_insert()    FUNCTION     �   CREATE FUNCTION material.material_stock_after_material_info_insert() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    INSERT INTO material.stock
       (uuid, material_uuid)
    VALUES
         (NEW.uuid, NEW.uuid);
    RETURN NEW;
END;
$$;
 D   DROP FUNCTION material.material_stock_after_material_info_insert();
       material          postgres    false    11            d           1255    17964 *   material_stock_after_material_trx_delete()    FUNCTION     l  CREATE FUNCTION material.material_stock_after_material_trx_delete() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    UPDATE material.stock
    SET 
    stock = stock + OLD.trx_quantity,
    lab_dip = lab_dip - CASE WHEN OLD.trx_to = 'lab_dip' THEN OLD.trx_quantity ELSE 0 END,
    tape_making = tape_making - CASE WHEN OLD.trx_to = 'tape_making' THEN OLD.trx_quantity ELSE 0 END,
    coil_forming = coil_forming - CASE WHEN OLD.trx_to = 'coil_forming' THEN OLD.trx_quantity ELSE 0 END,
    dying_and_iron = dying_and_iron - CASE WHEN OLD.trx_to = 'dying_and_iron' THEN OLD.trx_quantity ELSE 0 END,
    m_gapping = m_gapping - CASE WHEN OLD.trx_to = 'm_gapping' THEN OLD.trx_quantity ELSE 0 END,
    v_gapping = v_gapping - CASE WHEN OLD.trx_to = 'v_gapping' THEN OLD.trx_quantity ELSE 0 END,
    v_teeth_molding = v_teeth_molding - CASE WHEN OLD.trx_to = 'v_teeth_molding' THEN OLD.trx_quantity ELSE 0 END,
    m_teeth_molding = m_teeth_molding - CASE WHEN OLD.trx_to = 'm_teeth_molding' THEN OLD.trx_quantity ELSE 0 END,
    teeth_assembling_and_polishing = teeth_assembling_and_polishing - CASE WHEN OLD.trx_to = 'teeth_assembling_and_polishing' THEN OLD.trx_quantity ELSE 0 END,
    m_teeth_cleaning = m_teeth_cleaning - CASE WHEN OLD.trx_to = 'm_teeth_cleaning' THEN OLD.trx_quantity ELSE 0 END,
    v_teeth_cleaning = v_teeth_cleaning - CASE WHEN OLD.trx_to = 'v_teeth_cleaning' THEN OLD.trx_quantity ELSE 0 END,
    plating_and_iron = plating_and_iron - CASE WHEN OLD.trx_to = 'plating_and_iron' THEN OLD.trx_quantity ELSE 0 END,
    m_sealing = m_sealing - CASE WHEN OLD.trx_to = 'm_sealing' THEN OLD.trx_quantity ELSE 0 END,
    v_sealing = v_sealing - CASE WHEN OLD.trx_to = 'v_sealing' THEN OLD.trx_quantity ELSE 0 END,
    n_t_cutting = n_t_cutting - CASE WHEN OLD.trx_to = 'n_t_cutting' THEN OLD.trx_quantity ELSE 0 END,
    v_t_cutting = v_t_cutting - CASE WHEN OLD.trx_to = 'v_t_cutting' THEN OLD.trx_quantity ELSE 0 END,
    m_stopper = m_stopper - CASE WHEN OLD.trx_to = 'm_stopper' THEN OLD.trx_quantity ELSE 0 END,
    v_stopper = v_stopper - CASE WHEN OLD.trx_to = 'v_stopper' THEN OLD.trx_quantity ELSE 0 END,
    n_stopper = n_stopper - CASE WHEN OLD.trx_to = 'n_stopper' THEN OLD.trx_quantity ELSE 0 END,
    cutting = cutting - CASE WHEN OLD.trx_to = 'cutting' THEN OLD.trx_quantity ELSE 0 END,
    m_qc_and_packing = m_qc_and_packing - CASE WHEN OLD.trx_to = 'm_qc_and_packing' THEN OLD.trx_quantity ELSE 0 END,
    v_qc_and_packing = v_qc_and_packing - CASE WHEN OLD.trx_to = 'v_qc_and_packing' THEN OLD.trx_quantity ELSE 0 END,
    n_qc_and_packing = n_qc_and_packing - CASE WHEN OLD.trx_to = 'n_qc_and_packing' THEN OLD.trx_quantity ELSE 0 END,
    s_qc_and_packing = s_qc_and_packing - CASE WHEN OLD.trx_to = 's_qc_and_packing' THEN OLD.trx_quantity ELSE 0 END,
    die_casting = die_casting - CASE WHEN OLD.trx_to = 'die_casting' THEN OLD.trx_quantity ELSE 0 END,
    slider_assembly = slider_assembly - CASE WHEN OLD.trx_to = 'slider_assembly' THEN OLD.trx_quantity ELSE 0 END,
    coloring = coloring - CASE WHEN OLD.trx_to = 'coloring' THEN OLD.trx_quantity ELSE 0 END

    WHERE material_uuid = OLD.material_uuid;
    RETURN OLD;
END;
$$;
 C   DROP FUNCTION material.material_stock_after_material_trx_delete();
       material          postgres    false    11            Z           1255    17965 *   material_stock_after_material_trx_insert()    FUNCTION     l  CREATE FUNCTION material.material_stock_after_material_trx_insert() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    UPDATE material.stock
    SET 
    stock = stock -  NEW.trx_quantity,
    lab_dip = lab_dip + CASE WHEN NEW.trx_to = 'lab_dip' THEN NEW.trx_quantity ELSE 0 END,
    tape_making = tape_making + CASE WHEN NEW.trx_to = 'tape_making' THEN NEW.trx_quantity ELSE 0 END,
    coil_forming = coil_forming + CASE WHEN NEW.trx_to = 'coil_forming' THEN NEW.trx_quantity ELSE 0 END,
    dying_and_iron = dying_and_iron + CASE WHEN NEW.trx_to = 'dying_and_iron' THEN NEW.trx_quantity ELSE 0 END,
    m_gapping = m_gapping + CASE WHEN NEW.trx_to = 'm_gapping' THEN NEW.trx_quantity ELSE 0 END,
    v_gapping = v_gapping + CASE WHEN NEW.trx_to = 'v_gapping' THEN NEW.trx_quantity ELSE 0 END,
    v_teeth_molding = v_teeth_molding + CASE WHEN NEW.trx_to = 'v_teeth_molding' THEN NEW.trx_quantity ELSE 0 END,
    m_teeth_molding = m_teeth_molding + CASE WHEN NEW.trx_to = 'm_teeth_molding' THEN NEW.trx_quantity ELSE 0 END,
    teeth_assembling_and_polishing = teeth_assembling_and_polishing + CASE WHEN NEW.trx_to = 'teeth_assembling_and_polishing' THEN NEW.trx_quantity ELSE 0 END,
    m_teeth_cleaning = m_teeth_cleaning + CASE WHEN NEW.trx_to = 'm_teeth_cleaning' THEN NEW.trx_quantity ELSE 0 END,
    v_teeth_cleaning = v_teeth_cleaning + CASE WHEN NEW.trx_to = 'v_teeth_cleaning' THEN NEW.trx_quantity ELSE 0 END,
    plating_and_iron = plating_and_iron + CASE WHEN NEW.trx_to = 'plating_and_iron' THEN NEW.trx_quantity ELSE 0 END,
    m_sealing = m_sealing + CASE WHEN NEW.trx_to = 'm_sealing' THEN NEW.trx_quantity ELSE 0 END,
    v_sealing = v_sealing + CASE WHEN NEW.trx_to = 'v_sealing' THEN NEW.trx_quantity ELSE 0 END,
    n_t_cutting = n_t_cutting + CASE WHEN NEW.trx_to = 'n_t_cutting' THEN NEW.trx_quantity ELSE 0 END,
    v_t_cutting = v_t_cutting + CASE WHEN NEW.trx_to = 'v_t_cutting' THEN NEW.trx_quantity ELSE 0 END,
    m_stopper = m_stopper + CASE WHEN NEW.trx_to = 'm_stopper' THEN NEW.trx_quantity ELSE 0 END,
    v_stopper = v_stopper + CASE WHEN NEW.trx_to = 'v_stopper' THEN NEW.trx_quantity ELSE 0 END,
    n_stopper = n_stopper + CASE WHEN NEW.trx_to = 'n_stopper' THEN NEW.trx_quantity ELSE 0 END,
    cutting = cutting + CASE WHEN NEW.trx_to = 'cutting' THEN NEW.trx_quantity ELSE 0 END,
    m_qc_and_packing = m_qc_and_packing + CASE WHEN NEW.trx_to = 'm_qc_and_packing' THEN NEW.trx_quantity ELSE 0 END,
    v_qc_and_packing = v_qc_and_packing + CASE WHEN NEW.trx_to = 'v_qc_and_packing' THEN NEW.trx_quantity ELSE 0 END,
    n_qc_and_packing = n_qc_and_packing + CASE WHEN NEW.trx_to = 'n_qc_and_packing' THEN NEW.trx_quantity ELSE 0 END,
    s_qc_and_packing = s_qc_and_packing + CASE WHEN NEW.trx_to = 's_qc_and_packing' THEN NEW.trx_quantity ELSE 0 END,
    die_casting = die_casting + CASE WHEN NEW.trx_to = 'die_casting' THEN NEW.trx_quantity ELSE 0 END,
    slider_assembly = slider_assembly + CASE WHEN NEW.trx_to = 'slider_assembly' THEN NEW.trx_quantity ELSE 0 END,
    coloring = coloring + CASE WHEN NEW.trx_to = 'coloring' THEN NEW.trx_quantity ELSE 0 END
    WHERE material_uuid = NEW.material_uuid;
    RETURN NEW;
END;
$$;
 C   DROP FUNCTION material.material_stock_after_material_trx_insert();
       material          postgres    false    11            �           1255    17966 *   material_stock_after_material_trx_update()    FUNCTION     C  CREATE FUNCTION material.material_stock_after_material_trx_update() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    UPDATE material.stock
    SET 
    stock = stock - NEW.trx_quantity + OLD.trx_quantity,
    lab_dip = lab_dip + CASE WHEN NEW.trx_to = 'lab_dip' THEN NEW.trx_quantity ELSE 0 END - CASE WHEN OLD.trx_to = 'lab_dip' THEN OLD.trx_quantity ELSE 0 END,
    tape_making = tape_making + CASE WHEN NEW.trx_to = 'tape_making' THEN NEW.trx_quantity ELSE 0 END - CASE WHEN OLD.trx_to = 'tape_making' THEN OLD.trx_quantity ELSE 0 END,
    coil_forming = coil_forming + CASE WHEN NEW.trx_to = 'coil_forming' THEN NEW.trx_quantity ELSE 0 END - CASE WHEN OLD.trx_to = 'coil_forming' THEN OLD.trx_quantity ELSE 0 END,
    dying_and_iron = dying_and_iron + CASE WHEN NEW.trx_to = 'dying_and_iron' THEN NEW.trx_quantity ELSE 0 END - CASE WHEN OLD.trx_to = 'dying_and_iron' THEN OLD.trx_quantity ELSE 0 END,
    m_gapping = m_gapping + CASE WHEN NEW.trx_to = 'm_gapping' THEN NEW.trx_quantity ELSE 0 END - CASE WHEN OLD.trx_to = 'm_gapping' THEN OLD.trx_quantity ELSE 0 END,
    v_gapping = v_gapping + CASE WHEN NEW.trx_to = 'v_gapping' THEN NEW.trx_quantity ELSE 0 END - CASE WHEN OLD.trx_to = 'v_gapping' THEN OLD.trx_quantity ELSE 0 END,
    v_teeth_molding = v_teeth_molding + CASE WHEN NEW.trx_to = 'v_teeth_molding' THEN NEW.trx_quantity ELSE 0 END - CASE WHEN OLD.trx_to = 'v_teeth_molding' THEN OLD.trx_quantity ELSE 0 END,
    m_teeth_molding = m_teeth_molding + CASE WHEN NEW.trx_to = 'm_teeth_molding' THEN NEW.trx_quantity ELSE 0 END - CASE WHEN OLD.trx_to = 'm_teeth_molding' THEN OLD.trx_quantity ELSE 0 END,
    teeth_assembling_and_polishing = teeth_assembling_and_polishing + CASE WHEN NEW.trx_to = 'teeth_assembling_and_polishing' THEN NEW.trx_quantity ELSE 0 END - CASE WHEN OLD.trx_to = 'teeth_assembling_and_polishing' THEN OLD.trx_quantity ELSE 0 END,
    m_teeth_cleaning = m_teeth_cleaning + CASE WHEN NEW.trx_to = 'm_teeth_cleaning' THEN NEW.trx_quantity ELSE 0 END - CASE WHEN OLD.trx_to = 'm_teeth_cleaning' THEN OLD.trx_quantity ELSE 0 END,
    v_teeth_cleaning = v_teeth_cleaning + CASE WHEN NEW.trx_to = 'v_teeth_cleaning' THEN NEW.trx_quantity ELSE 0 END - CASE WHEN OLD.trx_to = 'v_teeth_cleaning' THEN OLD.trx_quantity ELSE 0 END,
    plating_and_iron = plating_and_iron + CASE WHEN NEW.trx_to = 'plating_and_iron' THEN NEW.trx_quantity ELSE 0 END - CASE WHEN OLD.trx_to = 'plating_and_iron' THEN OLD.trx_quantity ELSE 0 END,
    m_sealing = m_sealing + CASE WHEN NEW.trx_to = 'm_sealing' THEN NEW.trx_quantity ELSE 0 END - CASE WHEN OLD.trx_to = 'm_sealing' THEN OLD.trx_quantity ELSE 0 END,
    v_sealing = v_sealing + CASE WHEN NEW.trx_to = 'v_sealing' THEN NEW.trx_quantity ELSE 0 END - CASE WHEN OLD.trx_to = 'v_sealing' THEN OLD.trx_quantity ELSE 0 END,
    n_t_cutting = n_t_cutting + CASE WHEN NEW.trx_to = 'n_t_cutting' THEN NEW.trx_quantity ELSE 0 END - CASE WHEN OLD.trx_to = 'n_t_cutting' THEN OLD.trx_quantity ELSE 0 END,
    v_t_cutting = v_t_cutting + CASE WHEN NEW.trx_to = 'v_t_cutting' THEN NEW.trx_quantity ELSE 0 END - CASE WHEN OLD.trx_to = 'v_t_cutting' THEN OLD.trx_quantity ELSE 0 END,
    m_stopper = m_stopper + CASE WHEN NEW.trx_to = 'm_stopper' THEN NEW.trx_quantity ELSE 0 END - CASE WHEN OLD.trx_to = 'm_stopper' THEN OLD.trx_quantity ELSE 0 END,
    v_stopper = v_stopper + CASE WHEN NEW.trx_to = 'v_stopper' THEN NEW.trx_quantity ELSE 0 END - CASE WHEN OLD.trx_to = 'v_stopper' THEN OLD.trx_quantity ELSE 0 END,
    n_stopper = n_stopper + CASE WHEN NEW.trx_to = 'n_stopper' THEN NEW.trx_quantity ELSE 0 END - CASE WHEN OLD.trx_to = 'n_stopper' THEN OLD.trx_quantity ELSE 0 END,
    cutting = cutting + CASE WHEN NEW.trx_to = 'cutting' THEN NEW.trx_quantity ELSE 0 END - CASE WHEN OLD.trx_to = 'cutting' THEN OLD.trx_quantity ELSE 0 END,
    m_qc_and_packing = m_qc_and_packing + CASE WHEN NEW.trx_to = 'm_qc_and_packing' THEN NEW.trx_quantity ELSE 0 END - CASE WHEN OLD.trx_to = 'm_qc_and_packing' THEN OLD.trx_quantity ELSE 0 END,
    v_qc_and_packing = v_qc_and_packing + CASE WHEN NEW.trx_to = 'v_qc_and_packing' THEN NEW.trx_quantity ELSE 0 END - CASE WHEN OLD.trx_to = 'v_qc_and_packing' THEN OLD.trx_quantity ELSE 0 END,
    n_qc_and_packing = n_qc_and_packing + CASE WHEN NEW.trx_to = 'n_qc_and_packing' THEN NEW.trx_quantity ELSE 0 END - CASE WHEN OLD.trx_to = 'n_qc_and_packing' THEN OLD.trx_quantity ELSE 0 END,
    s_qc_and_packing = s_qc_and_packing + CASE WHEN NEW.trx_to = 's_qc_and_packing' THEN NEW.trx_quantity ELSE 0 END - CASE WHEN OLD.trx_to = 's_qc_and_packing' THEN OLD.trx_quantity ELSE 0 END,
    die_casting = die_casting + CASE WHEN NEW.trx_to = 'die_casting' THEN NEW.trx_quantity ELSE 0 END - CASE WHEN OLD.trx_to = 'die_casting' THEN OLD.trx_quantity ELSE 0 END,
    slider_assembly = slider_assembly + CASE WHEN NEW.trx_to = 'slider_assembly' THEN NEW.trx_quantity ELSE 0 END - CASE WHEN OLD.trx_to = 'slider_assembly' THEN OLD.trx_quantity ELSE 0 END,
    coloring = coloring + CASE WHEN NEW.trx_to = 'coloring' THEN NEW.trx_quantity ELSE 0 END - CASE WHEN OLD.trx_to = 'coloring' THEN OLD.trx_quantity ELSE 0 END
    WHERE material_uuid = NEW.material_uuid;
    RETURN NEW;
END;
$$;
 C   DROP FUNCTION material.material_stock_after_material_trx_update();
       material          postgres    false    11            _           1255    17967 +   material_stock_after_material_used_delete()    FUNCTION     �  CREATE FUNCTION material.material_stock_after_material_used_delete() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    UPDATE material.stock
    SET 
    lab_dip = lab_dip + CASE WHEN OLD.section = 'lab_dip' THEN OLD.used_quantity + OLD.wastage ELSE 0 END,
    tape_making = tape_making + CASE WHEN OLD.section = 'tape_making' THEN OLD.used_quantity + OLD.wastage ELSE 0 END,
    coil_forming = coil_forming + CASE WHEN OLD.section = 'coil_forming' THEN OLD.used_quantity + OLD.wastage ELSE 0 END,
    dying_and_iron = dying_and_iron + CASE WHEN OLD.section = 'dying_and_iron' THEN OLD.used_quantity + OLD.wastage ELSE 0 END,
    m_gapping = m_gapping + CASE WHEN OLD.section = 'm_gapping' THEN OLD.used_quantity + OLD.wastage ELSE 0 END,
    v_gapping = v_gapping + CASE WHEN OLD.section = 'v_gapping' THEN OLD.used_quantity + OLD.wastage ELSE 0 END,
    v_teeth_molding = v_teeth_molding + CASE WHEN OLD.section = 'v_teeth_molding' THEN OLD.used_quantity + OLD.wastage ELSE 0 END,
    m_teeth_molding = m_teeth_molding + CASE WHEN OLD.section = 'm_teeth_molding' THEN OLD.used_quantity + OLD.wastage ELSE 0 END,
    teeth_assembling_and_polishing = teeth_assembling_and_polishing + CASE WHEN OLD.section = 'teeth_assembling_and_polishing' THEN OLD.used_quantity + OLD.wastage ELSE 0 END,
    m_teeth_cleaning = m_teeth_cleaning + CASE WHEN OLD.section = 'm_teeth_cleaning' THEN OLD.used_quantity + OLD.wastage ELSE 0 END,
    v_teeth_cleaning = v_teeth_cleaning + CASE WHEN OLD.section = 'v_teeth_cleaning' THEN OLD.used_quantity + OLD.wastage ELSE 0 END,
    plating_and_iron = plating_and_iron + CASE WHEN OLD.section = 'plating_and_iron' THEN OLD.used_quantity + OLD.wastage ELSE 0 END,
    m_sealing = m_sealing + CASE WHEN OLD.section = 'm_sealing' THEN OLD.used_quantity + OLD.wastage ELSE 0 END,
    v_sealing = v_sealing + CASE WHEN OLD.section = 'v_sealing' THEN OLD.used_quantity + OLD.wastage ELSE 0 END,
    n_t_cutting = n_t_cutting + CASE WHEN OLD.section = 'n_t_cutting' THEN OLD.used_quantity + OLD.wastage ELSE 0 END,
    v_t_cutting = v_t_cutting + CASE WHEN OLD.section = 'v_t_cutting' THEN OLD.used_quantity + OLD.wastage ELSE 0 END,
    m_stopper = m_stopper + CASE WHEN OLD.section = 'm_stopper' THEN OLD.used_quantity + OLD.wastage ELSE 0 END,
    v_stopper = v_stopper + CASE WHEN OLD.section = 'v_stopper' THEN OLD.used_quantity + OLD.wastage ELSE 0 END,
    n_stopper = n_stopper + CASE WHEN OLD.section = 'n_stopper' THEN OLD.used_quantity + OLD.wastage ELSE 0 END,
    cutting = cutting + CASE WHEN OLD.section = 'cutting' THEN OLD.used_quantity + OLD.wastage ELSE 0 END,
    m_qc_and_packing = m_qc_and_packing + CASE WHEN OLD.section = 'm_qc_and_packing' THEN OLD.used_quantity + OLD.wastage ELSE 0 END,
    v_qc_and_packing = v_qc_and_packing + CASE WHEN OLD.section = 'v_qc_and_packing' THEN OLD.used_quantity + OLD.wastage ELSE 0 END,
    n_qc_and_packing = n_qc_and_packing + CASE WHEN OLD.section = 'n_qc_and_packing' THEN OLD.used_quantity + OLD.wastage ELSE 0 END,
    s_qc_and_packing = s_qc_and_packing + CASE WHEN OLD.section = 's_qc_and_packing' THEN OLD.used_quantity + OLD.wastage ELSE 0 END,
    die_casting = die_casting + CASE WHEN OLD.section = 'die_casting' THEN OLD.used_quantity + OLD.wastage ELSE 0 END,
    slider_assembly = slider_assembly + CASE WHEN OLD.section = 'slider_assembly' THEN OLD.used_quantity + OLD.wastage ELSE 0 END,
    coloring = coloring + CASE WHEN OLD.section = 'coloring' THEN OLD.used_quantity + OLD.wastage ELSE 0 END
    WHERE material_uuid = OLD.material_uuid;
    RETURN OLD;
END;
$$;
 D   DROP FUNCTION material.material_stock_after_material_used_delete();
       material          postgres    false    11            k           1255    17968 +   material_stock_after_material_used_insert()    FUNCTION     �  CREATE FUNCTION material.material_stock_after_material_used_insert() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    UPDATE material.stock
    SET 
    lab_dip = lab_dip - CASE WHEN NEW.section = 'lab_dip' THEN NEW.used_quantity + NEW.wastage ELSE 0 END,
    tape_making = tape_making - CASE WHEN NEW.section = 'tape_making' THEN NEW.used_quantity + NEW.wastage ELSE 0 END,
    coil_forming = coil_forming - CASE WHEN NEW.section = 'coil_forming' THEN NEW.used_quantity + NEW.wastage ELSE 0 END,
    dying_and_iron = dying_and_iron - CASE WHEN NEW.section = 'dying_and_iron' THEN NEW.used_quantity + NEW.wastage ELSE 0 END,
    m_gapping = m_gapping - CASE WHEN NEW.section = 'm_gapping' THEN NEW.used_quantity + NEW.wastage ELSE 0 END,
    v_gapping = v_gapping - CASE WHEN NEW.section = 'v_gapping' THEN NEW.used_quantity + NEW.wastage ELSE 0 END,
    v_teeth_molding = v_teeth_molding - CASE WHEN NEW.section = 'v_teeth_molding' THEN NEW.used_quantity + NEW.wastage ELSE 0 END,
    m_teeth_molding = m_teeth_molding - CASE WHEN NEW.section = 'm_teeth_molding' THEN NEW.used_quantity + NEW.wastage ELSE 0 END,
    teeth_assembling_and_polishing = teeth_assembling_and_polishing - CASE WHEN NEW.section = 'teeth_assembling_and_polishing' THEN NEW.used_quantity + NEW.wastage ELSE 0 END,
    m_teeth_cleaning = m_teeth_cleaning - CASE WHEN NEW.section = 'm_teeth_cleaning' THEN NEW.used_quantity + NEW.wastage ELSE 0 END,
    v_teeth_cleaning = v_teeth_cleaning - CASE WHEN NEW.section = 'v_teeth_cleaning' THEN NEW.used_quantity + NEW.wastage ELSE 0 END,
    plating_and_iron = plating_and_iron - CASE WHEN NEW.section = 'plating_and_iron' THEN NEW.used_quantity + NEW.wastage ELSE 0 END,
    m_sealing = m_sealing - CASE WHEN NEW.section = 'm_sealing' THEN NEW.used_quantity + NEW.wastage ELSE 0 END,
    v_sealing = v_sealing - CASE WHEN NEW.section = 'v_sealing' THEN NEW.used_quantity + NEW.wastage ELSE 0 END,
    n_t_cutting = n_t_cutting - CASE WHEN NEW.section = 'n_t_cutting' THEN NEW.used_quantity + NEW.wastage ELSE 0 END,
    v_t_cutting = v_t_cutting - CASE WHEN NEW.section = 'v_t_cutting' THEN NEW.used_quantity + NEW.wastage ELSE 0 END,
    m_stopper = m_stopper - CASE WHEN NEW.section = 'm_stopper' THEN NEW.used_quantity + NEW.wastage ELSE 0 END,
    v_stopper = v_stopper - CASE WHEN NEW.section = 'v_stopper' THEN NEW.used_quantity + NEW.wastage ELSE 0 END,
    n_stopper = n_stopper - CASE WHEN NEW.section = 'n_stopper' THEN NEW.used_quantity + NEW.wastage ELSE 0 END,
    cutting = cutting - CASE WHEN NEW.section = 'cutting' THEN NEW.used_quantity + NEW.wastage ELSE 0 END,
    m_qc_and_packing = m_qc_and_packing - CASE WHEN NEW.section = 'm_qc_and_packing' THEN NEW.used_quantity + NEW.wastage ELSE 0 END,
    v_qc_and_packing = v_qc_and_packing - CASE WHEN NEW.section = 'v_qc_and_packing' THEN NEW.used_quantity + NEW.wastage ELSE 0 END,
    n_qc_and_packing = n_qc_and_packing - CASE WHEN NEW.section = 'n_qc_and_packing' THEN NEW.used_quantity + NEW.wastage ELSE 0 END,
    s_qc_and_packing = s_qc_and_packing - CASE WHEN NEW.section = 's_qc_and_packing' THEN NEW.used_quantity + NEW.wastage ELSE 0 END,
    die_casting = die_casting - CASE WHEN NEW.section = 'die_casting' THEN NEW.used_quantity + NEW.wastage ELSE 0 END,
    slider_assembly = slider_assembly - CASE WHEN NEW.section = 'slider_assembly' THEN NEW.used_quantity + NEW.wastage ELSE 0 END,
    coloring = coloring - CASE WHEN NEW.section = 'coloring' THEN NEW.used_quantity + NEW.wastage ELSE 0 END
   
    WHERE material_uuid = NEW.material_uuid;
    RETURN NEW;
END;
$$;
 D   DROP FUNCTION material.material_stock_after_material_used_insert();
       material          postgres    false    11            X           1255    17969 +   material_stock_after_material_used_update()    FUNCTION     L  CREATE FUNCTION material.material_stock_after_material_used_update() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    UPDATE material.stock
    SET 
    lab_dip = lab_dip + 
    CASE WHEN NEW.section = 'lab_dip' THEN OLD.used_quantity + OLD.wastage ELSE 0 END,
    tape_making = tape_making + 
    CASE WHEN OLD.section = 'tape_making' THEN OLD.used_quantity + OLD.wastage ELSE 0 END,
    coil_forming = coil_forming + 
    CASE WHEN OLD.section = 'coil_forming' THEN OLD.used_quantity + OLD.wastage ELSE 0 END,
    dying_and_iron = dying_and_iron + 
    CASE WHEN OLD.section = 'dying_and_iron' THEN OLD.used_quantity + OLD.wastage ELSE 0 END,
    m_gapping = m_gapping + 
    CASE WHEN OLD.section = 'm_gapping' THEN OLD.used_quantity + OLD.wastage ELSE 0 END,
    v_gapping = v_gapping + 
    CASE WHEN OLD.section = 'v_gapping' THEN OLD.used_quantity + OLD.wastage ELSE 0 END,
    v_teeth_molding = v_teeth_molding + 
    CASE WHEN OLD.section = 'v_teeth_molding' THEN OLD.used_quantity + OLD.wastage ELSE 0 END,
    m_teeth_molding = m_teeth_molding + 
    CASE WHEN OLD.section = 'm_teeth_molding' THEN OLD.used_quantity + OLD.wastage ELSE 0 END,
    teeth_assembling_and_polishing = teeth_assembling_and_polishing + 
    CASE WHEN OLD.section = 'teeth_assembling_and_polishing' THEN OLD.used_quantity + OLD.wastage ELSE 0 END,
    m_teeth_cleaning = m_teeth_cleaning + 
    CASE WHEN OLD.section = 'm_teeth_cleaning' THEN OLD.used_quantity + OLD.wastage ELSE 0 END,
    v_teeth_cleaning = v_teeth_cleaning + 
    CASE WHEN OLD.section = 'v_teeth_cleaning' THEN OLD.used_quantity + OLD.wastage ELSE 0 END,
    plating_and_iron = plating_and_iron + 
    CASE WHEN OLD.section = 'plating_and_iron' THEN OLD.used_quantity + OLD.wastage ELSE 0 END,
    m_sealing = m_sealing + 
    CASE WHEN OLD.section = 'm_sealing' THEN OLD.used_quantity + OLD.wastage ELSE 0 END,
    v_sealing = v_sealing + 
    CASE WHEN OLD.section = 'v_sealing' THEN OLD.used_quantity + OLD.wastage ELSE 0 END,
    n_t_cutting = n_t_cutting + 
    CASE WHEN OLD.section = 'n_t_cutting' THEN OLD.used_quantity + OLD.wastage ELSE 0 END,
    v_t_cutting = v_t_cutting + 
    CASE WHEN OLD.section = 'v_t_cutting' THEN OLD.used_quantity + OLD.wastage ELSE 0 END,
    m_stopper = m_stopper + 
    CASE WHEN OLD.section = 'm_stopper' THEN OLD.used_quantity + OLD.wastage ELSE 0 END,
    v_stopper = v_stopper + 
    CASE WHEN OLD.section = 'v_stopper' THEN OLD.used_quantity + OLD.wastage ELSE 0 END,
    n_stopper = n_stopper + 
    CASE WHEN OLD.section = 'n_stopper' THEN OLD.used_quantity + OLD.wastage ELSE 0 END,
    cutting = cutting + 
    CASE WHEN OLD.section = 'cutting' THEN OLD.used_quantity + OLD.wastage ELSE 0 END,
    m_qc_and_packing = m_qc_and_packing + 
    CASE WHEN OLD.section = 'm_qc_and_packing' THEN OLD.used_quantity + OLD.wastage ELSE 0 END,
    v_qc_and_packing = v_qc_and_packing + 
    CASE WHEN OLD.section = 'v_qc_and_packing' THEN OLD.used_quantity + OLD.wastage ELSE 0 END,
    n_qc_and_packing = n_qc_and_packing + 
    CASE WHEN OLD.section = 'n_qc_and_packing' THEN OLD.used_quantity + OLD.wastage ELSE 0 END,
    s_qc_and_packing = s_qc_and_packing + 
    CASE WHEN OLD.section = 's_qc_and_packing' THEN OLD.used_quantity + OLD.wastage ELSE 0 END,
    die_casting = die_casting + 
    CASE WHEN OLD.section = 'die_casting' THEN OLD.used_quantity + OLD.wastage ELSE 0 END,
    slider_assembly = slider_assembly + 
    CASE WHEN OLD.section = 'slider_assembly' THEN OLD.used_quantity + OLD.wastage ELSE 0 END,
    coloring = coloring + 
    CASE WHEN OLD.section = 'coloring' THEN OLD.used_quantity + OLD.wastage ELSE 0 END
    WHERE material_uuid = NEW.material_uuid;

    UPDATE material.stock
    SET
    lab_dip = lab_dip -
    CASE WHEN NEW.section = 'lab_dip' THEN NEW.used_quantity + NEW.wastage ELSE 0 END,
    tape_making = tape_making -
    CASE WHEN NEW.section = 'tape_making' THEN NEW.used_quantity + NEW.wastage ELSE 0 END,
    coil_forming = coil_forming -
    CASE WHEN NEW.section = 'coil_forming' THEN NEW.used_quantity + NEW.wastage ELSE 0 END,
    dying_and_iron = dying_and_iron -
    CASE WHEN NEW.section = 'dying_and_iron' THEN NEW.used_quantity + NEW.wastage ELSE 0 END,
    m_gapping = m_gapping -
    CASE WHEN NEW.section = 'm_gapping' THEN NEW.used_quantity + NEW.wastage ELSE 0 END,
    v_gapping = v_gapping -
    CASE WHEN NEW.section = 'v_gapping' THEN NEW.used_quantity + NEW.wastage ELSE 0 END,
    v_teeth_molding = v_teeth_molding -
    CASE WHEN NEW.section = 'v_teeth_molding' THEN NEW.used_quantity + NEW.wastage ELSE 0 END,
    m_teeth_molding = m_teeth_molding -
    CASE WHEN NEW.section = 'm_teeth_molding' THEN NEW.used_quantity + NEW.wastage ELSE 0 END,
    teeth_assembling_and_polishing = teeth_assembling_and_polishing -
    CASE WHEN NEW.section = 'teeth_assembling_and_polishing' THEN NEW.used_quantity + NEW.wastage ELSE 0 END,
    m_teeth_cleaning = m_teeth_cleaning -
    CASE WHEN NEW.section = 'm_teeth_cleaning' THEN NEW.used_quantity + NEW.wastage ELSE 0 END,
    v_teeth_cleaning = v_teeth_cleaning -
    CASE WHEN NEW.section = 'v_teeth_cleaning' THEN NEW.used_quantity + NEW.wastage ELSE 0 END,
    plating_and_iron = plating_and_iron -
    CASE WHEN NEW.section = 'plating_and_iron' THEN NEW.used_quantity + NEW.wastage ELSE 0 END,
    m_sealing = m_sealing -
    CASE WHEN NEW.section = 'm_sealing' THEN NEW.used_quantity + NEW.wastage ELSE 0 END,
    v_sealing = v_sealing -
    CASE WHEN NEW.section = 'v_sealing' THEN NEW.used_quantity + NEW.wastage ELSE 0 END,
    n_t_cutting = n_t_cutting -
    CASE WHEN NEW.section = 'n_t_cutting' THEN NEW.used_quantity + NEW.wastage ELSE 0 END,
    v_t_cutting = v_t_cutting -
    CASE WHEN NEW.section = 'v_t_cutting' THEN NEW.used_quantity + NEW.wastage ELSE 0 END,
    m_stopper = m_stopper -
    CASE WHEN NEW.section = 'm_stopper' THEN NEW.used_quantity + NEW.wastage ELSE 0 END,
    v_stopper = v_stopper -
    CASE WHEN NEW.section = 'v_stopper' THEN NEW.used_quantity + NEW.wastage ELSE 0 END,
    n_stopper = n_stopper -
    CASE WHEN NEW.section = 'n_stopper' THEN NEW.used_quantity + NEW.wastage ELSE 0 END,
    cutting = cutting -
    CASE WHEN NEW.section = 'cutting' THEN NEW.used_quantity + NEW.wastage ELSE 0 END,
    m_qc_and_packing = m_qc_and_packing -
    CASE WHEN NEW.section = 'm_qc_and_packing' THEN NEW.used_quantity + NEW.wastage ELSE 0 END,
    v_qc_and_packing = v_qc_and_packing -
    CASE WHEN NEW.section = 'v_qc_and_packing' THEN NEW.used_quantity + NEW.wastage ELSE 0 END,
    n_qc_and_packing = n_qc_and_packing -
    CASE WHEN NEW.section = 'n_qc_and_packing' THEN NEW.used_quantity + NEW.wastage ELSE 0 END,
    s_qc_and_packing = s_qc_and_packing -
    CASE WHEN NEW.section = 's_qc_and_packing' THEN NEW.used_quantity + NEW.wastage ELSE 0 END,
    die_casting = die_casting -
    CASE WHEN NEW.section = 'die_casting' THEN NEW.used_quantity + NEW.wastage ELSE 0 END,
    slider_assembly = slider_assembly -
    CASE WHEN NEW.section = 'slider_assembly' THEN NEW.used_quantity + NEW.wastage ELSE 0 END,
    coloring = coloring -
    CASE WHEN NEW.section = 'coloring' THEN NEW.used_quantity + NEW.wastage ELSE 0 END
    WHERE material_uuid = NEW.material_uuid;
    RETURN NEW;
END;
$$;
 D   DROP FUNCTION material.material_stock_after_material_used_update();
       material          postgres    false    11            `           1255    17970 ,   material_stock_after_purchase_entry_delete()    FUNCTION       CREATE FUNCTION material.material_stock_after_purchase_entry_delete() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    UPDATE material.stock
        SET 
            stock = stock - OLD.quantity
    WHERE material_uuid = OLD.material_uuid;
    RETURN OLD;
END;

$$;
 E   DROP FUNCTION material.material_stock_after_purchase_entry_delete();
       material          postgres    false    11            �           1255    17971 ,   material_stock_after_purchase_entry_insert()    FUNCTION       CREATE FUNCTION material.material_stock_after_purchase_entry_insert() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    UPDATE material.stock
        SET 
            stock = stock + NEW.quantity
    WHERE material_uuid = NEW.material_uuid;
    RETURN NEW;
END;
$$;
 E   DROP FUNCTION material.material_stock_after_purchase_entry_insert();
       material          postgres    false    11            �           1255    17972 ,   material_stock_after_purchase_entry_update()    FUNCTION       CREATE FUNCTION material.material_stock_after_purchase_entry_update() RETURNS trigger
    LANGUAGE plpgsql
    AS $$

BEGIN
    IF NEW.material_uuid <> OLD.material_uuid THEN
        -- Deduct the old quantity from the old item's stock
        UPDATE material.stock
        SET stock = stock - OLD.quantity
        WHERE material_uuid = OLD.material_uuid;

        -- Add the new quantity to the new item's stock
        UPDATE material.stock
        SET stock = stock + NEW.quantity
        WHERE material_uuid = NEW.material_uuid;
    ELSE
        -- If the item has not changed, update the stock with the difference
        UPDATE material.stock
        SET stock = stock + NEW.quantity - OLD.quantity
        WHERE material_uuid = NEW.material_uuid;
    END IF;
    RETURN NEW;
END;

$$;
 E   DROP FUNCTION material.material_stock_after_purchase_entry_update();
       material          postgres    false    11            E           1255    17973 .   material_stock_sfg_after_stock_to_sfg_delete()    FUNCTION     4  CREATE FUNCTION material.material_stock_sfg_after_stock_to_sfg_delete() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    --Update material.stock table
    UPDATE material.stock 
    SET
        stock = stock + OLD.trx_quantity
    WHERE stock.material_uuid = OLD.material_uuid;

    --Update zipper.sfg table
    UPDATE zipper.sfg
    SET
        dying_and_iron_prod = dying_and_iron_prod 
            - CASE WHEN OLD.trx_to = 'dying_and_iron_prod' THEN OLD.trx_quantity ELSE 0 END,
        teeth_molding_stock = teeth_molding_stock 
            - CASE WHEN OLD.trx_to = 'teeth_molding_stock' THEN OLD.trx_quantity ELSE 0 END,
        teeth_molding_prod = teeth_molding_prod 
            - CASE WHEN OLD.trx_to = 'teeth_molding_prod' THEN OLD.trx_quantity ELSE 0 END,
        teeth_coloring_stock = teeth_coloring_stock
            - CASE WHEN OLD.trx_to = 'teeth_coloring_stock' THEN OLD.trx_quantity ELSE 0 END,
        teeth_coloring_prod = teeth_coloring_prod
            - CASE WHEN OLD.trx_to = 'teeth_coloring_prod' THEN OLD.trx_quantity ELSE 0 END,
        finishing_stock = finishing_stock
            - CASE WHEN OLD.trx_to = 'finishing_stock' THEN OLD.trx_quantity ELSE 0 END,
        finishing_prod = finishing_prod
            - CASE WHEN OLD.trx_to = 'finishing_prod' THEN OLD.trx_quantity ELSE 0 END,
        coloring_prod = coloring_prod
            - CASE WHEN OLD.trx_to = 'coloring_prod' THEN OLD.trx_quantity ELSE 0 END,
        warehouse = warehouse
            - CASE WHEN OLD.trx_to = 'warehouse' THEN OLD.trx_quantity ELSE 0 END,
        delivered = delivered
            - CASE WHEN OLD.trx_to = 'delivered' THEN OLD.trx_quantity ELSE 0 END,
        pi = pi 
            - CASE WHEN OLD.trx_to = 'pi' THEN OLD.trx_quantity ELSE 0 END
    WHERE order_entry_uuid = OLD.order_entry_uuid;

    RETURN OLD;
END;
$$;
 G   DROP FUNCTION material.material_stock_sfg_after_stock_to_sfg_delete();
       material          postgres    false    11            r           1255    17974 .   material_stock_sfg_after_stock_to_sfg_insert()    FUNCTION     =  CREATE FUNCTION material.material_stock_sfg_after_stock_to_sfg_insert() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    --Update material.stock table
    UPDATE material.stock 
    SET
        stock = stock - NEW.trx_quantity
    WHERE stock.material_uuid = NEW.material_uuid;

    --Update zipper.sfg table
    UPDATE zipper.sfg
    SET
        dying_and_iron_prod = dying_and_iron_prod 
            + CASE WHEN NEW.trx_to = 'dying_and_iron_prod' THEN NEW.trx_quantity ELSE 0 END,
        teeth_molding_stock = teeth_molding_stock 
            + CASE WHEN NEW.trx_to = 'teeth_molding_stock' THEN NEW.trx_quantity ELSE 0 END,
        teeth_molding_prod = teeth_molding_prod 
            + CASE WHEN NEW.trx_to = 'teeth_molding_prod' THEN NEW.trx_quantity ELSE 0 END,
        teeth_coloring_stock = teeth_coloring_stock
            + CASE WHEN NEW.trx_to = 'teeth_coloring_stock' THEN NEW.trx_quantity ELSE 0 END,
        teeth_coloring_prod = teeth_coloring_prod
            + CASE WHEN NEW.trx_to = 'teeth_coloring_prod' THEN NEW.trx_quantity ELSE 0 END,
        finishing_stock = finishing_stock
            + CASE WHEN NEW.trx_to = 'finishing_stock' THEN NEW.trx_quantity ELSE 0 END,
        finishing_prod = finishing_prod
            + CASE WHEN NEW.trx_to = 'finishing_prod' THEN NEW.trx_quantity ELSE 0 END,
        coloring_prod = coloring_prod
            + CASE WHEN NEW.trx_to = 'coloring_prod' THEN NEW.trx_quantity ELSE 0 END,
        warehouse = warehouse
            + CASE WHEN NEW.trx_to = 'warehouse' THEN NEW.trx_quantity ELSE 0 END,
        delivered = delivered
            + CASE WHEN NEW.trx_to = 'delivered' THEN NEW.trx_quantity ELSE 0 END,
        pi = pi 
            + CASE WHEN NEW.trx_to = 'pi' THEN NEW.trx_quantity ELSE 0 END
        
    WHERE order_entry_uuid = NEW.order_entry_uuid;
    RETURN NEW;

END;
$$;
 G   DROP FUNCTION material.material_stock_sfg_after_stock_to_sfg_insert();
       material          postgres    false    11            �           1255    17975 .   material_stock_sfg_after_stock_to_sfg_update()    FUNCTION       CREATE FUNCTION material.material_stock_sfg_after_stock_to_sfg_update() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    --Update material.stock table
    UPDATE material.stock 
    SET
        stock = stock - NEW.trx_quantity + OLD.trx_quantity
    WHERE stock.material_uuid = NEW.material_uuid;

    --Update zipper.sfg table
    UPDATE zipper.sfg
    SET
        dying_and_iron_prod = dying_and_iron_prod 
            + CASE WHEN NEW.trx_to = 'dying_and_iron_prod' THEN NEW.trx_quantity ELSE 0 END
            - CASE WHEN OLD.trx_to = 'dying_and_iron_prod' THEN OLD.trx_quantity ELSE 0 END,
        teeth_molding_stock = teeth_molding_stock 
            + CASE WHEN NEW.trx_to = 'teeth_molding_stock' THEN NEW.trx_quantity ELSE 0 END
            - CASE WHEN OLD.trx_to = 'teeth_molding_stock' THEN OLD.trx_quantity ELSE 0 END,
        teeth_molding_prod = teeth_molding_prod 
            + CASE WHEN NEW.trx_to = 'teeth_molding_prod' THEN NEW.trx_quantity ELSE 0 END
            - CASE WHEN OLD.trx_to = 'teeth_molding_prod' THEN OLD.trx_quantity ELSE 0 END,
        teeth_coloring_stock = teeth_coloring_stock
            + CASE WHEN NEW.trx_to = 'teeth_coloring_stock' THEN NEW.trx_quantity ELSE 0 END
            - CASE WHEN OLD.trx_to = 'teeth_coloring_stock' THEN OLD.trx_quantity ELSE 0 END,
        teeth_coloring_prod = teeth_coloring_prod
            + CASE WHEN NEW.trx_to = 'teeth_coloring_prod' THEN NEW.trx_quantity ELSE 0 END
            - CASE WHEN OLD.trx_to = 'teeth_coloring_prod' THEN OLD.trx_quantity ELSE 0 END,
        finishing_stock = finishing_stock
            + CASE WHEN NEW.trx_to = 'finishing_stock' THEN NEW.trx_quantity ELSE 0 END
            - CASE WHEN OLD.trx_to = 'finishing_stock' THEN OLD.trx_quantity ELSE 0 END,
        finishing_prod = finishing_prod
            + CASE WHEN NEW.trx_to = 'finishing_prod' THEN NEW.trx_quantity ELSE 0 END
            - CASE WHEN OLD.trx_to = 'finishing_prod' THEN OLD.trx_quantity ELSE 0 END,
        coloring_prod = coloring_prod
            + CASE WHEN NEW.trx_to = 'coloring_prod' THEN NEW.trx_quantity ELSE 0 END
            - CASE WHEN OLD.trx_to = 'coloring_prod' THEN OLD.trx_quantity ELSE 0 END,
        warehouse = warehouse
            + CASE WHEN NEW.trx_to = 'warehouse' THEN NEW.trx_quantity ELSE 0 END
            - CASE WHEN OLD.trx_to = 'warehouse' THEN OLD.trx_quantity ELSE 0 END,
        delivered = delivered
            + CASE WHEN NEW.trx_to = 'delivered' THEN NEW.trx_quantity ELSE 0 END
            - CASE WHEN OLD.trx_to = 'delivered' THEN OLD.trx_quantity ELSE 0 END,
        pi = pi
            + CASE WHEN NEW.trx_to = 'pi' THEN NEW.trx_quantity ELSE 0 END
            - CASE WHEN OLD.trx_to = 'pi' THEN OLD.trx_quantity ELSE 0 END
    WHERE order_entry_uuid = NEW.order_entry_uuid;

    RETURN NEW;

END;
$$;
 G   DROP FUNCTION material.material_stock_sfg_after_stock_to_sfg_update();
       material          postgres    false    11            �           1255    131272 >   thread_batch_entry_after_batch_entry_production_delete_funct()    FUNCTION     �  CREATE FUNCTION public.thread_batch_entry_after_batch_entry_production_delete_funct() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    UPDATE thread.batch_entry
    SET
        coning_production_quantity = coning_production_quantity - OLD.production_quantity,
        coning_carton_quantity = coning_carton_quantity - OLD.coning_carton_quantity
    WHERE uuid = OLD.batch_entry_uuid;

    UPDATE thread.order_entry
    SET
        production_quantity = production_quantity - OLD.production_quantity
        -- production_quantity_in_kg = production_quantity_in_kg - OLD.production_quantity_in_kg

    WHERE uuid = (SELECT order_entry_uuid FROM thread.batch_entry WHERE uuid = OLD.batch_entry_uuid);

    RETURN OLD;
END;

$$;
 U   DROP FUNCTION public.thread_batch_entry_after_batch_entry_production_delete_funct();
       public          postgres    false            �           1255    131271 >   thread_batch_entry_after_batch_entry_production_insert_funct()    FUNCTION     �  CREATE FUNCTION public.thread_batch_entry_after_batch_entry_production_insert_funct() RETURNS trigger
    LANGUAGE plpgsql
    AS $$

BEGIN
    UPDATE thread.batch_entry
    SET
        coning_production_quantity = coning_production_quantity + NEW.production_quantity,
        coning_carton_quantity = coning_carton_quantity + NEW.coning_carton_quantity
    WHERE uuid = NEW.batch_entry_uuid;

    UPDATE thread.order_entry
    SET
        production_quantity = production_quantity + NEW.production_quantity
        -- production_quantity_in_kg = production_quantity_in_kg + NEW.production_quantity_in_kg

    WHERE uuid = (SELECT order_entry_uuid FROM thread.batch_entry WHERE uuid = NEW.batch_entry_uuid);

    RETURN NEW;
END;

$$;
 U   DROP FUNCTION public.thread_batch_entry_after_batch_entry_production_insert_funct();
       public          postgres    false            M           1255    131273 >   thread_batch_entry_after_batch_entry_production_update_funct()    FUNCTION     P  CREATE FUNCTION public.thread_batch_entry_after_batch_entry_production_update_funct() RETURNS trigger
    LANGUAGE plpgsql
    AS $$

BEGIN
    UPDATE thread.batch_entry
    SET
        coning_production_quantity = coning_production_quantity - OLD.production_quantity + NEW.production_quantity,
        coning_carton_quantity = coning_carton_quantity - OLD.coning_carton_quantity + NEW.coning_carton_quantity
    WHERE uuid = NEW.batch_entry_uuid;

    UPDATE thread.order_entry
    SET
        production_quantity = production_quantity - OLD.production_quantity + NEW.production_quantity
        -- production_quantity_in_kg = production_quantity_in_kg - OLD.production_quantity_in_kg + NEW.production_quantity_in_kg

    WHERE uuid = (SELECT order_entry_uuid FROM thread.batch_entry WHERE uuid = NEW.batch_entry_uuid);

    RETURN NEW;
END;

$$;
 U   DROP FUNCTION public.thread_batch_entry_after_batch_entry_production_update_funct();
       public          postgres    false            u           1255    131278 A   thread_batch_entry_and_order_entry_after_batch_entry_trx_delete()    FUNCTION        CREATE FUNCTION public.thread_batch_entry_and_order_entry_after_batch_entry_trx_delete() RETURNS trigger
    LANGUAGE plpgsql
    AS $$

BEGIN
    UPDATE thread.batch_entry
    SET
        transfer_quantity = transfer_quantity - OLD.quantity,
        coning_production_quantity = coning_production_quantity + OLD.quantity,
        transfer_carton_quantity = transfer_carton_quantity - OLD.carton_quantity,
        coning_carton_quantity = coning_carton_quantity + OLD.carton_quantity
    WHERE uuid = OLD.batch_entry_uuid;

    UPDATE thread.order_entry
    SET
        warehouse = warehouse - OLD.quantity,
        carton_quantity = carton_quantity - OLD.carton_quantity
    WHERE uuid = (SELECT order_entry_uuid FROM thread.batch_entry WHERE uuid = OLD.batch_entry_uuid);
    RETURN OLD;
END;

$$;
 X   DROP FUNCTION public.thread_batch_entry_and_order_entry_after_batch_entry_trx_delete();
       public          postgres    false            �           1255    131277 @   thread_batch_entry_and_order_entry_after_batch_entry_trx_funct()    FUNCTION       CREATE FUNCTION public.thread_batch_entry_and_order_entry_after_batch_entry_trx_funct() RETURNS trigger
    LANGUAGE plpgsql
    AS $$

BEGIN
    UPDATE thread.batch_entry
    SET
        transfer_quantity = transfer_quantity + NEW.quantity,
        coning_production_quantity = coning_production_quantity - NEW.quantity,
        transfer_carton_quantity = transfer_carton_quantity + NEW.carton_quantity,
        coning_carton_quantity = coning_carton_quantity - NEW.carton_quantity
    WHERE uuid = NEW.batch_entry_uuid;

    UPDATE thread.order_entry
    SET
        warehouse = warehouse + NEW.quantity,
        carton_quantity = carton_quantity + NEW.carton_quantity
    WHERE uuid = (SELECT order_entry_uuid FROM thread.batch_entry WHERE uuid = NEW.batch_entry_uuid);
    RETURN NEW;
END;

$$;
 W   DROP FUNCTION public.thread_batch_entry_and_order_entry_after_batch_entry_trx_funct();
       public          postgres    false            �           1255    131279 A   thread_batch_entry_and_order_entry_after_batch_entry_trx_update()    FUNCTION     �  CREATE FUNCTION public.thread_batch_entry_and_order_entry_after_batch_entry_trx_update() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    UPDATE thread.batch_entry
    SET
        transfer_quantity = transfer_quantity - OLD.quantity + NEW.quantity,
        coning_production_quantity = coning_production_quantity + OLD.quantity - NEW.quantity,
        transfer_carton_quantity = transfer_carton_quantity - OLD.carton_quantity + NEW.carton_quantity,
        coning_carton_quantity = coning_carton_quantity + OLD.carton_quantity - NEW.carton_quantity
    WHERE uuid = NEW.batch_entry_uuid;

    UPDATE thread.order_entry
    SET
        warehouse = warehouse - OLD.quantity + NEW.quantity,
        carton_quantity = carton_quantity - OLD.carton_quantity + NEW.carton_quantity
    WHERE uuid = (SELECT order_entry_uuid FROM thread.batch_entry WHERE uuid = NEW.batch_entry_uuid);
    RETURN NEW;
END;

$$;
 X   DROP FUNCTION public.thread_batch_entry_and_order_entry_after_batch_entry_trx_update();
       public          postgres    false            U           1255    65738 2   zipper_batch_entry_after_batch_production_delete()    FUNCTION     F  CREATE FUNCTION public.zipper_batch_entry_after_batch_production_delete() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
  UPDATE zipper.batch_entry
    SET
        production_quantity_in_kg = production_quantity_in_kg - OLD.production_quantity_in_kg
    WHERE
        uuid = OLD.batch_entry_uuid;
    
    UPDATE zipper.sfg
    SET
        dying_and_iron_prod = dying_and_iron_prod - OLD.production_quantity_in_kg
        FROM zipper.batch_entry
    WHERE
         zipper.sfg.uuid = batch_entry.sfg_uuid AND batch_entry.uuid = OLD.batch_entry_uuid;
    RETURN OLD;
END;

$$;
 I   DROP FUNCTION public.zipper_batch_entry_after_batch_production_delete();
       public          postgres    false            n           1255    65736 2   zipper_batch_entry_after_batch_production_insert()    FUNCTION     7  CREATE FUNCTION public.zipper_batch_entry_after_batch_production_insert() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
  UPDATE zipper.batch_entry
    SET
        production_quantity_in_kg = production_quantity_in_kg + NEW.production_quantity_in_kg
    WHERE
        uuid = NEW.batch_entry_uuid;

 UPDATE zipper.sfg
    SET
        dying_and_iron_prod = dying_and_iron_prod + NEW.production_quantity_in_kg
    FROM zipper.batch_entry
    WHERE
        zipper.sfg.uuid = batch_entry.sfg_uuid AND batch_entry.uuid = NEW.batch_entry_uuid;
RETURN NEW;

END;

$$;
 I   DROP FUNCTION public.zipper_batch_entry_after_batch_production_insert();
       public          postgres    false            A           1255    65737 2   zipper_batch_entry_after_batch_production_update()    FUNCTION     �  CREATE FUNCTION public.zipper_batch_entry_after_batch_production_update() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
  UPDATE zipper.batch_entry
    SET
        production_quantity_in_kg = production_quantity_in_kg + NEW.production_quantity_in_kg - OLD.production_quantity_in_kg
    WHERE
        uuid = NEW.batch_entry_uuid;

  UPDATE zipper.sfg
    SET
        dying_and_iron_prod = dying_and_iron_prod + NEW.production_quantity_in_kg - OLD.production_quantity_in_kg
        FROM zipper.batch_entry
    WHERE
         zipper.sfg.uuid = batch_entry.sfg_uuid AND batch_entry.uuid = NEW.batch_entry_uuid;
    RETURN NEW;

RETURN NEW;
      
END;

$$;
 I   DROP FUNCTION public.zipper_batch_entry_after_batch_production_update();
       public          postgres    false            c           1255    65744 %   zipper_sfg_after_batch_entry_delete()    FUNCTION     #  CREATE FUNCTION public.zipper_sfg_after_batch_entry_delete() RETURNS trigger
    LANGUAGE plpgsql
    AS $$

BEGIN
  UPDATE zipper.sfg
    SET
        dying_and_iron_prod = dying_and_iron_prod - OLD.production_quantity_in_kg
    WHERE
        uuid = OLD.sfg_uuid;

    RETURN OLD;
END;

$$;
 <   DROP FUNCTION public.zipper_sfg_after_batch_entry_delete();
       public          postgres    false            t           1255    65742 %   zipper_sfg_after_batch_entry_insert()    FUNCTION     %  CREATE FUNCTION public.zipper_sfg_after_batch_entry_insert() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
  UPDATE zipper.sfg
    SET
        dying_and_iron_prod = dying_and_iron_prod + NEW.production_quantity_in_kg
    WHERE
        uuid = NEW.sfg_uuid;
    
    RETURN NEW;
END;
$$;
 <   DROP FUNCTION public.zipper_sfg_after_batch_entry_insert();
       public          postgres    false            |           1255    65743 %   zipper_sfg_after_batch_entry_update()    FUNCTION     E  CREATE FUNCTION public.zipper_sfg_after_batch_entry_update() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
  UPDATE zipper.sfg
    SET
        dying_and_iron_prod = dying_and_iron_prod + NEW.production_quantity_in_kg - OLD.production_quantity_in_kg
    WHERE
        uuid = NEW.sfg_uuid;

    RETURN NEW;	
END;



$$;
 <   DROP FUNCTION public.zipper_sfg_after_batch_entry_update();
       public          postgres    false            �           1255    81959 A   assembly_stock_after_die_casting_to_assembly_stock_delete_funct()    FUNCTION       CREATE FUNCTION slider.assembly_stock_after_die_casting_to_assembly_stock_delete_funct() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    -- Update slider.assembly_stock
    UPDATE slider.assembly_stock
    SET
        quantity = quantity - OLD.production_quantity
    WHERE uuid = OLD.assembly_stock_uuid;

    -- die casting body
    UPDATE slider.die_casting
    SET quantity_in_sa = quantity_in_sa + OLD.production_quantity + OLD.wastage
    FROM slider.assembly_stock
    WHERE slider.die_casting.uuid = assembly_stock.die_casting_body_uuid AND assembly_stock.uuid = OLD.assembly_stock_uuid;

    -- die casting cap
    UPDATE slider.die_casting
    SET quantity_in_sa = quantity_in_sa + OLD.production_quantity + OLD.wastage
    FROM slider.assembly_stock
    WHERE slider.die_casting.uuid = assembly_stock.die_casting_cap_uuid AND assembly_stock.uuid = OLD.assembly_stock_uuid;

    -- die casting puller
    UPDATE slider.die_casting
    SET quantity_in_sa = quantity_in_sa + OLD.production_quantity + OLD.wastage
    FROM slider.assembly_stock
    WHERE slider.die_casting.uuid = assembly_stock.die_casting_puller_uuid AND assembly_stock.uuid = OLD.assembly_stock_uuid;

    -- die casting link
    UPDATE slider.die_casting
    SET quantity_in_sa = quantity_in_sa + CASE WHEN OLD.with_link = 1 THEN OLD.production_quantity + OLD.wastage ELSE 0 END
    FROM slider.assembly_stock
    WHERE slider.die_casting.uuid = assembly_stock.die_casting_link_uuid AND assembly_stock.uuid = OLD.assembly_stock_uuid;

    RETURN OLD;
END;
$$;
 X   DROP FUNCTION slider.assembly_stock_after_die_casting_to_assembly_stock_delete_funct();
       slider          postgres    false    13            �           1255    81957 A   assembly_stock_after_die_casting_to_assembly_stock_insert_funct()    FUNCTION       CREATE FUNCTION slider.assembly_stock_after_die_casting_to_assembly_stock_insert_funct() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    -- Update slider.assembly_stock
    UPDATE slider.assembly_stock
    SET
        quantity = quantity + NEW.production_quantity
    WHERE uuid = NEW.assembly_stock_uuid;

    -- die casting body 
    UPDATE slider.die_casting 
    SET quantity_in_sa = quantity_in_sa - NEW.production_quantity - NEW.wastage
    FROM slider.assembly_stock
    WHERE slider.die_casting.uuid = assembly_stock.die_casting_body_uuid AND assembly_stock.uuid = NEW.assembly_stock_uuid;

    -- die casting cap
    UPDATE slider.die_casting
    SET quantity_in_sa = quantity_in_sa - NEW.production_quantity - NEW.wastage
    FROM slider.assembly_stock
    WHERE slider.die_casting.uuid = assembly_stock.die_casting_cap_uuid AND assembly_stock.uuid = NEW.assembly_stock_uuid;

    -- die casting puller
    UPDATE slider.die_casting
    SET quantity_in_sa = quantity_in_sa - NEW.production_quantity - NEW.wastage
    FROM slider.assembly_stock
    WHERE slider.die_casting.uuid = assembly_stock.die_casting_puller_uuid AND assembly_stock.uuid = NEW.assembly_stock_uuid;

    -- die casting link
    UPDATE slider.die_casting
    SET quantity_in_sa = quantity_in_sa - CASE WHEN NEW.with_link = 1 THEN NEW.production_quantity - NEW.wastage ELSE 0 END
    FROM slider.assembly_stock
    WHERE slider.die_casting.uuid = assembly_stock.die_casting_link_uuid AND assembly_stock.uuid = NEW.assembly_stock_uuid;

    RETURN NEW;
END;
$$;
 X   DROP FUNCTION slider.assembly_stock_after_die_casting_to_assembly_stock_insert_funct();
       slider          postgres    false    13            �           1255    81958 A   assembly_stock_after_die_casting_to_assembly_stock_update_funct()    FUNCTION     
  CREATE FUNCTION slider.assembly_stock_after_die_casting_to_assembly_stock_update_funct() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    -- Update slider.assembly_stock
    UPDATE slider.assembly_stock
    SET
        quantity = quantity 
            + NEW.production_quantity
            - OLD.production_quantity
    WHERE uuid = NEW.assembly_stock_uuid;

    -- die casting body
    UPDATE slider.die_casting
    SET quantity_in_sa = quantity_in_sa - NEW.production_quantity - NEW.wastage + OLD.production_quantity + OLD.wastage
    FROM slider.assembly_stock
    WHERE slider.die_casting.uuid = assembly_stock.die_casting_body_uuid AND assembly_stock.uuid = NEW.assembly_stock_uuid;

    -- die casting cap
    UPDATE slider.die_casting
    SET quantity_in_sa = quantity_in_sa - NEW.production_quantity - NEW.wastage + OLD.production_quantity + OLD.wastage
    FROM slider.assembly_stock
    WHERE slider.die_casting.uuid = assembly_stock.die_casting_cap_uuid AND assembly_stock.uuid = NEW.assembly_stock_uuid;

    -- die casting puller
    UPDATE slider.die_casting
    SET quantity_in_sa = quantity_in_sa - NEW.production_quantity - NEW.wastage + OLD.production_quantity + OLD.wastage
    FROM slider.assembly_stock
    WHERE slider.die_casting.uuid = assembly_stock.die_casting_puller_uuid AND assembly_stock.uuid = NEW.assembly_stock_uuid;

    -- die casting link
    UPDATE slider.die_casting
    SET quantity_in_sa = quantity_in_sa - CASE WHEN NEW.with_link = 1 THEN NEW.production_quantity + NEW.wastage ELSE 0 END + CASE WHEN OLD.with_link = 1 THEN OLD.production_quantity + OLD.wastage ELSE 0 END
    FROM slider.assembly_stock
    WHERE slider.die_casting.uuid = assembly_stock.die_casting_link_uuid AND assembly_stock.uuid = NEW.assembly_stock_uuid;

    RETURN NEW;
END;
$$;
 X   DROP FUNCTION slider.assembly_stock_after_die_casting_to_assembly_stock_update_funct();
       slider          postgres    false    13            l           1255    17976 8   slider_die_casting_after_die_casting_production_delete()    FUNCTION     |  CREATE FUNCTION slider.slider_die_casting_after_die_casting_production_delete() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
--update slider.die_casting table
    UPDATE slider.die_casting
        SET 
        quantity = quantity - (OLD.cavity_goods * OLD.push),
        weight = weight - OLD.weight
        WHERE uuid = OLD.die_casting_uuid;
    RETURN OLD;
    END;
$$;
 O   DROP FUNCTION slider.slider_die_casting_after_die_casting_production_delete();
       slider          postgres    false    13            z           1255    17977 8   slider_die_casting_after_die_casting_production_insert()    FUNCTION     }  CREATE FUNCTION slider.slider_die_casting_after_die_casting_production_insert() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN 
--update slider.die_casting table
    UPDATE slider.die_casting
        SET 
        quantity = quantity + (NEW.cavity_goods * NEW.push),
        weight = weight + NEW.weight
        WHERE uuid = NEW.die_casting_uuid;
    RETURN NEW;
    END;
$$;
 O   DROP FUNCTION slider.slider_die_casting_after_die_casting_production_insert();
       slider          postgres    false    13            W           1255    17978 8   slider_die_casting_after_die_casting_production_update()    FUNCTION     �  CREATE FUNCTION slider.slider_die_casting_after_die_casting_production_update() RETURNS trigger
    LANGUAGE plpgsql
    AS $$

BEGIN

--update slider.die_casting table

    UPDATE slider.die_casting
        SET 
        quantity = quantity + (NEW.cavity_goods * NEW.push) - (OLD.cavity_goods * OLD.push),
        weight = weight + NEW.weight - OLD.weight
        WHERE uuid = NEW.die_casting_uuid;
    RETURN NEW;
    END;

$$;
 O   DROP FUNCTION slider.slider_die_casting_after_die_casting_production_update();
       slider          postgres    false    13            V           1255    17979 3   slider_die_casting_after_trx_against_stock_delete()    FUNCTION     �  CREATE FUNCTION slider.slider_die_casting_after_trx_against_stock_delete() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
--update slider.die_casting table
    UPDATE slider.die_casting
        SET 
        quantity_in_sa = quantity_in_sa - OLD.quantity,
        quantity = quantity + OLD.quantity,
        weight = weight + OLD.weight
        WHERE uuid = OLD.die_casting_uuid;
    RETURN OLD;
    END;
$$;
 J   DROP FUNCTION slider.slider_die_casting_after_trx_against_stock_delete();
       slider          postgres    false    13            �           1255    17980 3   slider_die_casting_after_trx_against_stock_insert()    FUNCTION     �  CREATE FUNCTION slider.slider_die_casting_after_trx_against_stock_insert() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
--update slider.die_casting table
    UPDATE slider.die_casting
        SET 
        quantity_in_sa = quantity_in_sa + NEW.quantity,
        quantity = quantity - NEW.quantity,
        weight = weight - NEW.weight
        WHERE uuid = NEW.die_casting_uuid;

    RETURN NEW;
END;
$$;
 J   DROP FUNCTION slider.slider_die_casting_after_trx_against_stock_insert();
       slider          postgres    false    13            w           1255    17981 3   slider_die_casting_after_trx_against_stock_update()    FUNCTION     �  CREATE FUNCTION slider.slider_die_casting_after_trx_against_stock_update() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
--update slider.die_casting table
    UPDATE slider.die_casting
        SET 

        quantity_in_sa = quantity_in_sa + NEW.quantity - OLD.quantity,
        quantity = quantity - NEW.quantity + OLD.quantity,
        weight = weight - NEW.weight + OLD.weight
        WHERE uuid = NEW.die_casting_uuid;

    RETURN NEW;
END;
$$;
 J   DROP FUNCTION slider.slider_die_casting_after_trx_against_stock_update();
       slider          postgres    false    13            L           1255    17982 0   slider_stock_after_coloring_transaction_delete()    FUNCTION       CREATE FUNCTION slider.slider_stock_after_coloring_transaction_delete() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    -- Update slider.stock table
    UPDATE slider.stock
    SET
        sa_prod = CASE WHEN uuid = OLD.stock_uuid THEN sa_prod + OLD.trx_quantity ELSE sa_prod END,
        coloring_stock = CASE WHEN order_info_uuid = OLD.order_info_uuid THEN coloring_stock - OLD.trx_quantity ELSE coloring_stock END

    WHERE uuid = OLD.stock_uuid OR order_info_uuid = OLD.order_info_uuid;

    RETURN OLD;
END;

$$;
 G   DROP FUNCTION slider.slider_stock_after_coloring_transaction_delete();
       slider          postgres    false    13            Y           1255    17983 0   slider_stock_after_coloring_transaction_insert()    FUNCTION       CREATE FUNCTION slider.slider_stock_after_coloring_transaction_insert() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    -- Update slider.stock table
    UPDATE slider.stock
    SET
        sa_prod = CASE WHEN uuid = NEW.stock_uuid THEN sa_prod - NEW.trx_quantity ELSE sa_prod END,
        coloring_stock = CASE WHEN order_info_uuid = NEW.order_info_uuid THEN coloring_stock + NEW.trx_quantity ELSE coloring_stock END

    WHERE uuid = NEW.stock_uuid OR order_info_uuid = NEW.order_info_uuid;

    RETURN NEW;
END;
$$;
 G   DROP FUNCTION slider.slider_stock_after_coloring_transaction_insert();
       slider          postgres    false    13            �           1255    17984 0   slider_stock_after_coloring_transaction_update()    FUNCTION     7  CREATE FUNCTION slider.slider_stock_after_coloring_transaction_update() RETURNS trigger
    LANGUAGE plpgsql
    AS $$

BEGIN
    -- Update slider.stock table
    UPDATE slider.stock
    SET
        sa_prod = CASE WHEN uuid = NEW.stock_uuid THEN sa_prod - NEW.trx_quantity + OLD.trx_quantity ELSE sa_prod END,
        coloring_stock = CASE WHEN order_info_uuid = NEW.order_info_uuid THEN coloring_stock + NEW.trx_quantity - OLD.trx_quantity ELSE coloring_stock END

    WHERE uuid = NEW.stock_uuid OR order_info_uuid = NEW.order_info_uuid;

    RETURN NEW;
END;

$$;
 G   DROP FUNCTION slider.slider_stock_after_coloring_transaction_update();
       slider          postgres    false    13            @           1255    17985 3   slider_stock_after_die_casting_transaction_delete()    FUNCTION     �  CREATE FUNCTION slider.slider_stock_after_die_casting_transaction_delete() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
 UPDATE slider.die_casting
    SET
        quantity = quantity + OLD.trx_quantity,
        weight = weight + OLD.weight
    WHERE uuid = OLD.die_casting_uuid;

    --update slider.stock table
    UPDATE slider.stock
    SET
        body_quantity = body_quantity 
            - CASE WHEN dc.type = 'body' THEN OLD.trx_quantity ELSE 0 END,
        puller_quantity = puller_quantity 
            - CASE WHEN dc.type = 'puller' THEN OLD.trx_quantity ELSE 0 END,
        cap_quantity = cap_quantity 
            - CASE WHEN dc.type = 'cap' THEN OLD.trx_quantity ELSE 0 END,
        link_quantity = link_quantity 
            - CASE WHEN dc.type = 'link' THEN OLD.trx_quantity ELSE 0 END,
        h_bottom_quantity = h_bottom_quantity 
            - CASE WHEN dc.type = 'h_bottom' THEN OLD.trx_quantity ELSE 0 END,
        u_top_quantity = u_top_quantity 
            - CASE WHEN dc.type = 'u_top' THEN OLD.trx_quantity ELSE 0 END,
        box_pin_quantity = box_pin_quantity 
            - CASE WHEN dc.type = 'box_pin' THEN OLD.trx_quantity ELSE 0 END,
        two_way_pin_quantity = two_way_pin_quantity 
            - CASE WHEN dc.type = 'two_way_pin' THEN OLD.trx_quantity ELSE 0 END
    FROM slider.die_casting dc
    WHERE stock.uuid = NEW.stock_uuid AND dc.uuid = NEW.die_casting_uuid;


RETURN OLD;
END;

$$;
 J   DROP FUNCTION slider.slider_stock_after_die_casting_transaction_delete();
       slider          postgres    false    13            D           1255    17986 3   slider_stock_after_die_casting_transaction_insert()    FUNCTION     �  CREATE FUNCTION slider.slider_stock_after_die_casting_transaction_insert() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    --update slider.stock table
    UPDATE slider.die_casting
    SET
        quantity = quantity - NEW.trx_quantity,
        weight = weight - NEW.weight
    WHERE uuid = NEW.die_casting_uuid;

    UPDATE slider.stock
    SET
        body_quantity = body_quantity 
            + CASE WHEN dc.type = 'body' THEN NEW.trx_quantity ELSE 0 END,
        puller_quantity = puller_quantity 
            + CASE WHEN dc.type = 'puller' THEN NEW.trx_quantity ELSE 0 END,
        cap_quantity = cap_quantity 
            + CASE WHEN dc.type = 'cap' THEN NEW.trx_quantity ELSE 0 END,
        link_quantity = link_quantity 
            + CASE WHEN dc.type = 'link' THEN NEW.trx_quantity ELSE 0 END,
        h_bottom_quantity = h_bottom_quantity 
            + CASE WHEN dc.type = 'h_bottom' THEN NEW.trx_quantity ELSE 0 END,
        u_top_quantity = u_top_quantity 
            + CASE WHEN dc.type = 'u_top' THEN NEW.trx_quantity ELSE 0 END,
        box_pin_quantity = box_pin_quantity 
            + CASE WHEN dc.type = 'box_pin' THEN NEW.trx_quantity ELSE 0 END,
        two_way_pin_quantity = two_way_pin_quantity 
            + CASE WHEN dc.type = 'two_way_pin' THEN NEW.trx_quantity ELSE 0 END
    FROM slider.die_casting dc
    WHERE stock.uuid = NEW.stock_uuid AND dc.uuid = NEW.die_casting_uuid;

RETURN NEW;
END;
$$;
 J   DROP FUNCTION slider.slider_stock_after_die_casting_transaction_insert();
       slider          postgres    false    13            j           1255    17987 3   slider_stock_after_die_casting_transaction_update()    FUNCTION     *  CREATE FUNCTION slider.slider_stock_after_die_casting_transaction_update() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    --update slider.stock table
    UPDATE slider.die_casting
    SET
        quantity = quantity - NEW.trx_quantity + OLD.trx_quantity,
        weight = weight - NEW.weight + OLD.weight
    WHERE uuid = NEW.die_casting_uuid;

    UPDATE slider.stock
    SET
        body_quantity = body_quantity 
            + CASE WHEN dc.type = 'body' THEN NEW.trx_quantity ELSE 0 END 
            - CASE WHEN dc.type = 'body' THEN OLD.trx_quantity ELSE 0 END,
        puller_quantity = puller_quantity 
            + CASE WHEN dc.type = 'puller' THEN NEW.trx_quantity ELSE 0 END 
            - CASE WHEN dc.type = 'puller' THEN OLD.trx_quantity ELSE 0 END,
        cap_quantity = cap_quantity 
            + CASE WHEN dc.type = 'cap' THEN NEW.trx_quantity ELSE 0 END 
            - CASE WHEN dc.type = 'cap' THEN OLD.trx_quantity ELSE 0 END,
        link_quantity = link_quantity 
            + CASE WHEN dc.type = 'link' THEN NEW.trx_quantity ELSE 0 END 
            - CASE WHEN dc.type = 'link' THEN OLD.trx_quantity ELSE 0 END,
        h_bottom_quantity = h_bottom_quantity 
            + CASE WHEN dc.type = 'h_bottom' THEN NEW.trx_quantity ELSE 0 END 
            - CASE WHEN dc.type = 'h_bottom' THEN OLD.trx_quantity ELSE 0 END,
        u_top_quantity = u_top_quantity 
            + CASE WHEN dc.type = 'u_top' THEN NEW.trx_quantity ELSE 0 END 
            - CASE WHEN dc.type = 'u_top' THEN OLD.trx_quantity ELSE 0 END,
        box_pin_quantity = box_pin_quantity 
            + CASE WHEN dc.type = 'box_pin' THEN NEW.trx_quantity ELSE 0 END 
            - CASE WHEN dc.type = 'box_pin' THEN OLD.trx_quantity ELSE 0 END,
        two_way_pin_quantity = two_way_pin_quantity 
            + CASE WHEN dc.type = 'two_way_pin' THEN NEW.trx_quantity ELSE 0 END 
            - CASE WHEN dc.type = 'two_way_pin' THEN OLD.trx_quantity ELSE 0 END
    FROM slider.die_casting dc
    WHERE stock.uuid = NEW.stock_uuid AND dc.uuid = NEW.die_casting_uuid;

RETURN NEW;
END;

$$;
 J   DROP FUNCTION slider.slider_stock_after_die_casting_transaction_update();
       slider          postgres    false    13            C           1255    17988 -   slider_stock_after_slider_production_delete()    FUNCTION     �  CREATE FUNCTION slider.slider_stock_after_slider_production_delete() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
   
    -- Update slider.stock table for 'sa_prod' section
    IF OLD.section = 'sa_prod' THEN
        UPDATE slider.stock
        SET
            sa_prod = sa_prod - OLD.production_quantity,
            body_quantity =  body_quantity + OLD.production_quantity,
            cap_quantity = cap_quantity + OLD.production_quantity,
            puller_quantity = puller_quantity + OLD.production_quantity,
            link_quantity = link_quantity + CASE WHEN OLD.with_link = 1 THEN OLD.production_quantity ELSE 0 END
        FROM zipper.v_order_details_full vodf
        WHERE vodf.order_description_uuid = stock.order_description_uuid AND stock.uuid = OLD.stock_uuid;
    END IF;

    -- Update slider.stock table for 'coloring' section
    IF OLD.section = 'coloring' THEN
        UPDATE slider.stock
        SET
            coloring_stock = coloring_stock + OLD.production_quantity,
            link_quantity = link_quantity + OLD.production_quantity,
            box_pin_quantity = box_pin_quantity + CASE WHEN lower(vodf.end_type_name) = 'open end' THEN OLD.production_quantity ELSE 0 END,
            h_bottom_quantity = h_bottom_quantity + CASE WHEN lower(vodf.end_type_name) = 'close end' THEN OLD.production_quantity ELSE 0 END,
            u_top_quantity = u_top_quantity + (2 * OLD.production_quantity),
            coloring_prod = coloring_prod - OLD.production_quantity
        FROM zipper.v_order_details_full vodf
        WHERE vodf.order_description_uuid = stock.order_description_uuid AND stock.uuid = OLD.stock_uuid;
    END IF;

    RETURN OLD;
END;
$$;
 D   DROP FUNCTION slider.slider_stock_after_slider_production_delete();
       slider          postgres    false    13            �           1255    17989 -   slider_stock_after_slider_production_insert()    FUNCTION     o  CREATE FUNCTION slider.slider_stock_after_slider_production_insert() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    -- Update slider.stock table for 'sa_prod' section
   
      IF NEW.section = 'sa_prod' THEN
            UPDATE slider.stock
            SET
                sa_prod = sa_prod + NEW.production_quantity,
                body_quantity =  body_quantity - NEW.production_quantity,
                cap_quantity = cap_quantity - NEW.production_quantity,
                puller_quantity = puller_quantity - NEW.production_quantity,
                link_quantity = link_quantity - CASE WHEN NEW.with_link = 1 THEN NEW.production_quantity ELSE 0 END
            WHERE stock.uuid = NEW.stock_uuid;
    END IF;

-- Update slider.stock table for 'coloring' section

    IF NEW.section = 'coloring' THEN

        UPDATE slider.stock
            SET
                coloring_stock = coloring_stock - NEW.production_quantity,
                link_quantity = link_quantity - NEW.production_quantity,
                box_pin_quantity = box_pin_quantity - CASE WHEN lower(vodf.end_type_name) = 'open end' THEN NEW.production_quantity ELSE 0 END,
                h_bottom_quantity = h_bottom_quantity - CASE WHEN lower(vodf.end_type_name) = 'close end' THEN NEW.production_quantity ELSE 0 END,
                u_top_quantity = u_top_quantity - (2 * NEW.production_quantity),
                coloring_prod = coloring_prod + NEW.production_quantity
            FROM zipper.v_order_details_full vodf
        WHERE vodf.order_description_uuid = stock.order_description_uuid AND stock.uuid = NEW.stock_uuid;
    END IF;

    RETURN NEW;
END;
$$;
 D   DROP FUNCTION slider.slider_stock_after_slider_production_insert();
       slider          postgres    false    13            �           1255    17990 -   slider_stock_after_slider_production_update()    FUNCTION     {  CREATE FUNCTION slider.slider_stock_after_slider_production_update() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    -- Update slider.stock table for 'sa_prod' section
    IF NEW.section = 'sa_prod' THEN
        UPDATE slider.stock
        SET
            sa_prod = sa_prod + NEW.production_quantity - OLD.production_quantity,
            body_quantity =  body_quantity - NEW.production_quantity + OLD.production_quantity,
            cap_quantity = cap_quantity - NEW.production_quantity + OLD.production_quantity,
            puller_quantity = puller_quantity - NEW.production_quantity + OLD.production_quantity,
            link_quantity = link_quantity - CASE WHEN NEW.with_link = 1 THEN NEW.production_quantity ELSE 0 END + CASE WHEN OLD.with_link = 1 THEN OLD.production_quantity ELSE 0 END
        WHERE stock.uuid = NEW.stock_uuid;
    END IF;

    -- Update slider.stock table for 'coloring' section
    IF NEW.section = 'coloring' THEN
        UPDATE slider.stock
        SET
            coloring_stock = coloring_stock - NEW.production_quantity + OLD.production_quantity,
            link_quantity = link_quantity - NEW.production_quantity + OLD.production_quantity,
            box_pin_quantity = box_pin_quantity - CASE WHEN lower(vodf.end_type_name) = 'open end' THEN NEW.production_quantity - OLD.production_quantity ELSE 0 END,
            h_bottom_quantity = h_bottom_quantity - CASE WHEN lower(vodf.end_type_name) = 'close end' THEN NEW.production_quantity - OLD.production_quantity ELSE 0 END,
            u_top_quantity = u_top_quantity - (2 * (NEW.production_quantity - OLD.production_quantity)),
            coloring_prod = coloring_prod + NEW.production_quantity - OLD.production_quantity
            FROM zipper.v_order_details_full vodf
        WHERE vodf.order_description_uuid = stock.order_description_uuid AND stock.uuid = NEW.stock_uuid;
    END IF;

    RETURN NEW;
END;
$$;
 D   DROP FUNCTION slider.slider_stock_after_slider_production_update();
       slider          postgres    false    13            G           1255    17991 '   slider_stock_after_transaction_delete()    FUNCTION     {  CREATE FUNCTION slider.slider_stock_after_transaction_delete() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    --update slider.stock table
    UPDATE slider.stock
    SET
        sa_prod = sa_prod + CASE WHEN OLD.from_section = 'sa_prod' THEN OLD.trx_quantity ELSE 0 END
        - CASE WHEN OLD.to_section = 'sa_prod' THEN OLD.trx_quantity ELSE 0 END,
        coloring_stock = coloring_stock + CASE WHEN OLD.from_section = 'coloring_stock' THEN OLD.trx_quantity ELSE 0 END
        - CASE WHEN OLD.to_section = 'coloring_stock' THEN OLD.trx_quantity ELSE 0 END
    WHERE uuid = OLD.stock_uuid;

    IF OLD.from_section = 'coloring_prod' AND OLD.to_section = 'trx_to_finishing'
    THEN
        UPDATE slider.stock
        SET
        coloring_prod = coloring_prod + OLD.trx_quantity,
        trx_to_finishing = trx_to_finishing - OLD.trx_quantity
        WHERE uuid = OLD.stock_uuid;

        UPDATE zipper.order_description
        SET
        slider_finishing_stock = slider_finishing_stock - OLD.trx_quantity
        WHERE uuid = (SELECT order_description_uuid FROM slider.stock WHERE uuid = OLD.stock_uuid);
        
    END IF;

    IF OLD.assembly_stock_uuid IS NOT NULL
    THEN
        UPDATE slider.stock
        SET
            coloring_stock = coloring_stock - CASE WHEN OLD.to_section = 'assembly_stock_to_coloring_stock' THEN OLD.trx_quantity ELSE 0 END
        WHERE uuid = OLD.stock_uuid;

        UPDATE slider.assembly_stock
        SET
            quantity = quantity + CASE WHEN OLD.from_section = 'assembly_stock' THEN OLD.trx_quantity ELSE 0 END
        WHERE uuid = OLD.assembly_stock_uuid;
    END IF;

    RETURN OLD;
END;
$$;
 >   DROP FUNCTION slider.slider_stock_after_transaction_delete();
       slider          postgres    false    13            �           1255    17992 '   slider_stock_after_transaction_insert()    FUNCTION     r  CREATE FUNCTION slider.slider_stock_after_transaction_insert() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    --update slider.stock table
    UPDATE slider.stock
    SET
        sa_prod = sa_prod - CASE WHEN NEW.from_section = 'sa_prod' THEN NEW.trx_quantity ELSE 0 END
        + CASE WHEN NEW.to_section = 'sa_prod' THEN NEW.trx_quantity ELSE 0 END,
        coloring_stock = coloring_stock - CASE WHEN NEW.from_section = 'coloring_stock' THEN NEW.trx_quantity ELSE 0 END
        + CASE WHEN NEW.to_section = 'coloring_stock' THEN NEW.trx_quantity ELSE 0 END
    WHERE uuid = NEW.stock_uuid;

    IF NEW.from_section = 'coloring_prod' AND NEW.to_section = 'trx_to_finishing'
    THEN
        UPDATE slider.stock
        SET
        coloring_prod = coloring_prod - NEW.trx_quantity,
        trx_to_finishing = trx_to_finishing + NEW.trx_quantity
        WHERE uuid = NEW.stock_uuid;

        UPDATE zipper.order_description
        SET
        slider_finishing_stock = slider_finishing_stock + NEW.trx_quantity
        WHERE uuid = (SELECT order_description_uuid FROM slider.stock WHERE uuid = NEW.stock_uuid);
    END IF;

    IF NEW.assembly_stock_uuid IS NOT NULL
    THEN
        UPDATE slider.stock
        SET
            coloring_stock = coloring_stock + CASE WHEN NEW.to_section = 'assembly_stock_to_coloring_stock' THEN NEW.trx_quantity ELSE 0 END
        WHERE uuid = NEW.stock_uuid;

        UPDATE slider.assembly_stock
        SET
            quantity = quantity - CASE WHEN NEW.from_section = 'assembly_stock' THEN NEW.trx_quantity ELSE 0 END
        WHERE uuid = NEW.assembly_stock_uuid;
    END IF;

    RETURN NEW;
END;
$$;
 >   DROP FUNCTION slider.slider_stock_after_transaction_insert();
       slider          postgres    false    13            I           1255    17993 '   slider_stock_after_transaction_update()    FUNCTION     k
  CREATE FUNCTION slider.slider_stock_after_transaction_update() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    --update slider.stock table
    UPDATE slider.stock
    SET
        
        sa_prod = sa_prod 
        - CASE WHEN NEW.from_section = 'sa_prod' THEN NEW.trx_quantity ELSE 0 END
        + CASE WHEN NEW.to_section = 'sa_prod' THEN NEW.trx_quantity ELSE 0 END
        + CASE WHEN OLD.from_section = 'sa_prod' THEN OLD.trx_quantity ELSE 0 END
        - CASE WHEN OLD.to_section = 'sa_prod' THEN OLD.trx_quantity ELSE 0 END,
        coloring_stock = coloring_stock 
        - CASE WHEN NEW.from_section = 'coloring_stock' THEN NEW.trx_quantity ELSE 0 END
        + CASE WHEN NEW.to_section = 'coloring_stock' THEN NEW.trx_quantity ELSE 0 END
        + CASE WHEN OLD.from_section = 'coloring_stock' THEN OLD.trx_quantity ELSE 0 END
        - CASE WHEN OLD.to_section = 'coloring_stock' THEN OLD.trx_quantity ELSE 0 END
    WHERE uuid = NEW.stock_uuid;

    IF NEW.from_section = 'coloring_prod' AND NEW.to_section = 'trx_to_finishing'
    THEN
        UPDATE slider.stock
        SET
        coloring_prod = coloring_prod - NEW.trx_quantity + OLD.trx_quantity,
        trx_to_finishing = trx_to_finishing + NEW.trx_quantity - OLD.trx_quantity
        WHERE uuid = NEW.stock_uuid;

        UPDATE zipper.order_description
        SET
        slider_finishing_stock = slider_finishing_stock + NEW.trx_quantity - OLD.trx_quantity
        WHERE uuid = (SELECT order_description_uuid FROM slider.stock WHERE uuid = NEW.stock_uuid);
        
    END IF;

    -- assembly_stock_uuid -> OLD
    IF OLD.assembly_stock_uuid IS NOT NULL
    THEN
        UPDATE slider.stock
        SET
            coloring_stock = coloring_stock 
            - CASE WHEN OLD.to_section = 'assembly_stock_to_coloring_stock' THEN OLD.trx_quantity ELSE 0 END
        WHERE uuid = OLD.stock_uuid;

        UPDATE slider.assembly_stock
        SET
            quantity = quantity 
            + CASE WHEN OLD.from_section = 'assembly_stock' THEN OLD.trx_quantity ELSE 0 END
        WHERE uuid = OLD.assembly_stock_uuid;
    END IF;

    -- assembly_stock_uuid -> NEW
    IF NEW.assembly_stock_uuid IS NOT NULL
    THEN
        UPDATE slider.stock
        SET
            coloring_stock = coloring_stock + CASE WHEN NEW.to_section = 'assembly_stock_to_coloring_stock' THEN NEW.trx_quantity ELSE 0 END
        WHERE uuid = NEW.stock_uuid;

        UPDATE slider.assembly_stock
        SET
            quantity = quantity - CASE WHEN NEW.from_section = 'assembly_stock' THEN NEW.trx_quantity ELSE 0 END
        WHERE uuid = NEW.assembly_stock_uuid;
    END IF;

    RETURN NEW;
END;
$$;
 >   DROP FUNCTION slider.slider_stock_after_transaction_update();
       slider          postgres    false    13            }           1255    131171 *   order_entry_after_batch_is_drying_update()    FUNCTION     �  CREATE FUNCTION thread.order_entry_after_batch_is_drying_update() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    -- Handle insert when is_drying_complete is true

    IF TG_OP = 'UPDATE' AND NEW.is_drying_complete = '1' THEN
        -- Update order_entry table
        UPDATE thread.order_entry
        SET production_quantity = production_quantity + NEW.quantity
        WHERE uuid = (SELECT order_entry_uuid FROM thread.batch_entry WHERE batch_uuid = NEW.uuid);

        -- Update batch_entry table
        UPDATE thread.batch_entry
        SET quantity = quantity - NEW.quantity
        WHERE batch_uuid = NEW.uuid;

    -- Handle remove when is_drying_complete changes from true to false

    ELSIF TG_OP = 'UPDATE' AND OLD.is_drying_complete = '1' AND NEW.is_drying_complete = '0' THEN
        -- Update order_entry table
        UPDATE thread.order_entry
        SET production_quantity = production_quantity - OLD.quantity
        WHERE uuid = (SELECT order_entry_uuid FROM thread.batch_entry WHERE batch_uuid = NEW.uuid);

        -- Update batch_entry table
        UPDATE thread.batch_entry
        SET quantity = quantity + OLD.quantity
        WHERE batch_uuid = NEW.uuid;
    END IF;

    RETURN NEW;
END;
$$;
 A   DROP FUNCTION thread.order_entry_after_batch_is_drying_update();
       thread          postgres    false    14            �           1255    131169 *   order_entry_after_batch_is_dyeing_update()    FUNCTION       CREATE FUNCTION thread.order_entry_after_batch_is_dyeing_update() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    RAISE NOTICE 'Trigger executing for batch UUID: %', NEW.uuid;

    -- Update order_entry
    UPDATE thread.order_entry oe
    SET 
        production_quantity = production_quantity 
        + CASE WHEN (NEW.is_drying_complete = 'true' AND OLD.is_drying_complete = 'false') THEN be.quantity ELSE 0 END 
        - CASE WHEN (NEW.is_drying_complete = 'false' AND OLD.is_drying_complete = 'true') THEN be.quantity ELSE 0 END
    FROM thread.batch_entry be
    LEFT JOIN thread.batch b ON be.batch_uuid = b.uuid
    WHERE b.uuid = NEW.uuid AND oe.uuid = be.order_entry_uuid;
    RAISE NOTICE 'Trigger executed for batch UUID: %', NEW.uuid;
    RETURN NEW;
END;
$$;
 A   DROP FUNCTION thread.order_entry_after_batch_is_dyeing_update();
       thread          postgres    false    14            a           1255    17994 6   order_description_after_dyed_tape_transaction_delete()    FUNCTION     �  CREATE FUNCTION zipper.order_description_after_dyed_tape_transaction_delete() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    -- Update order_description
    UPDATE zipper.order_description
    SET
        tape_received = tape_received + OLD.trx_quantity,
        tape_transferred = tape_transferred - OLD.trx_quantity
    WHERE order_description.uuid = OLD.order_description_uuid;

    RETURN OLD;
END;

$$;
 M   DROP FUNCTION zipper.order_description_after_dyed_tape_transaction_delete();
       zipper          postgres    false    15            x           1255    17995 6   order_description_after_dyed_tape_transaction_insert()    FUNCTION     �  CREATE FUNCTION zipper.order_description_after_dyed_tape_transaction_insert() RETURNS trigger
    LANGUAGE plpgsql
    AS $$

BEGIN
    -- Update order_description
    UPDATE zipper.order_description
    SET
        tape_received = tape_received - NEW.trx_quantity,
        tape_transferred = tape_transferred + NEW.trx_quantity
    WHERE order_description.uuid = NEW.order_description_uuid;

    RETURN NEW;
END;

$$;
 M   DROP FUNCTION zipper.order_description_after_dyed_tape_transaction_insert();
       zipper          postgres    false    15            �           1255    17996 6   order_description_after_dyed_tape_transaction_update()    FUNCTION     �  CREATE FUNCTION zipper.order_description_after_dyed_tape_transaction_update() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    -- Update order_description
    UPDATE zipper.order_description
    SET
        tape_received = tape_received + OLD.trx_quantity - NEW.trx_quantity,
        tape_transferred = tape_transferred + NEW.trx_quantity - OLD.trx_quantity
    WHERE order_description.uuid = NEW.order_description_uuid;

    RETURN NEW;
END;

$$;
 M   DROP FUNCTION zipper.order_description_after_dyed_tape_transaction_update();
       zipper          postgres    false    15            �           1255    24577 4   order_description_after_tape_coil_to_dyeing_delete()    FUNCTION     �  CREATE FUNCTION zipper.order_description_after_tape_coil_to_dyeing_delete() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    UPDATE zipper.tape_coil
        SET
            quantity_in_coil = CASE WHEN lower(properties.name) = 'nylon' THEN quantity_in_coil + OLD.trx_quantity ELSE quantity_in_coil END,
            quantity = CASE WHEN lower(properties.name) = 'nylon' THEN quantity ELSE quantity + OLD.trx_quantity END
        FROM public.properties
        WHERE tape_coil.uuid = OLD.tape_coil_uuid AND properties.uuid = tape_coil.item_uuid;

        UPDATE zipper.order_description
        SET
            tape_received = tape_received - OLD.trx_quantity
        WHERE uuid = OLD.order_description_uuid;

        RETURN OLD;
    END;
$$;
 K   DROP FUNCTION zipper.order_description_after_tape_coil_to_dyeing_delete();
       zipper          postgres    false    15            R           1255    24576 4   order_description_after_tape_coil_to_dyeing_insert()    FUNCTION     �  CREATE FUNCTION zipper.order_description_after_tape_coil_to_dyeing_insert() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN

    UPDATE zipper.tape_coil
    SET
        quantity_in_coil = CASE WHEN lower(properties.name) = 'nylon' THEN quantity_in_coil - NEW.trx_quantity ELSE quantity_in_coil END,
        quantity = CASE WHEN lower(properties.name) = 'nylon' THEN quantity ELSE quantity - NEW.trx_quantity END
    FROM public.properties
    WHERE tape_coil.uuid = NEW.tape_coil_uuid AND properties.uuid = tape_coil.item_uuid;
    
    UPDATE zipper.order_description
    SET
        tape_received = tape_received + NEW.trx_quantity
    WHERE uuid = NEW.order_description_uuid;

    RETURN NEW;
END;
$$;
 K   DROP FUNCTION zipper.order_description_after_tape_coil_to_dyeing_insert();
       zipper          postgres    false    15            H           1255    24578 4   order_description_after_tape_coil_to_dyeing_update()    FUNCTION     �  CREATE FUNCTION zipper.order_description_after_tape_coil_to_dyeing_update() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    UPDATE zipper.tape_coil
    SET
        quantity_in_coil = CASE WHEN lower(properties.name) = 'nylon' THEN quantity_in_coil + OLD.trx_quantity - NEW.trx_quantity ELSE quantity_in_coil END,
        quantity = CASE WHEN lower(properties.name) = 'nylon' THEN quantity ELSE quantity + OLD.trx_quantity - NEW.trx_quantity END
    FROM public.properties
    WHERE tape_coil.uuid = NEW.tape_coil_uuid AND properties.uuid = tape_coil.item_uuid;

    UPDATE zipper.order_description
    SET
        tape_received = tape_received - OLD.trx_quantity + NEW.trx_quantity
    WHERE uuid = NEW.order_description_uuid;

    RETURN NEW;
END;

$$;
 K   DROP FUNCTION zipper.order_description_after_tape_coil_to_dyeing_update();
       zipper          postgres    false    15            h           1255    17997    sfg_after_order_entry_delete()    FUNCTION     �   CREATE FUNCTION zipper.sfg_after_order_entry_delete() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    DELETE FROM zipper.sfg
    WHERE order_entry_uuid = OLD.uuid;
    RETURN OLD;
END;
$$;
 5   DROP FUNCTION zipper.sfg_after_order_entry_delete();
       zipper          postgres    false    15            J           1255    17998    sfg_after_order_entry_insert()    FUNCTION       CREATE FUNCTION zipper.sfg_after_order_entry_insert() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    INSERT INTO zipper.sfg (
        uuid, 
        order_entry_uuid
    ) VALUES (
        NEW.uuid, 
        NEW.uuid
    );
    RETURN NEW;
END;
$$;
 5   DROP FUNCTION zipper.sfg_after_order_entry_insert();
       zipper          postgres    false    15            \           1255    17999 *   sfg_after_sfg_production_delete_function()    FUNCTION     �  CREATE FUNCTION zipper.sfg_after_sfg_production_delete_function() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
DECLARE 
    item_name TEXT;
    od_uuid TEXT;
    nylon_stopper_name TEXT;
BEGIN
    -- Fetch item_name and order_description_uuid once
    SELECT vodf.item_name, oe.order_description_uuid, vodf.nylon_stopper_name INTO item_name, od_uuid, nylon_stopper_name
    FROM zipper.sfg sfg
    LEFT JOIN zipper.order_entry oe ON oe.uuid = sfg.order_entry_uuid
    LEFT JOIN zipper.v_order_details_full vodf ON oe.order_description_uuid = vodf.order_description_uuid
    WHERE sfg.uuid = OLD.sfg_uuid;

    -- Update order_description based on item_name
    IF lower(item_name) = 'metal' THEN
        UPDATE zipper.order_description od
        SET 
            tape_transferred = tape_transferred + 
                CASE 
                    WHEN OLD.section = 'teeth_molding' THEN OLD.production_quantity_in_kg + OLD.wastage 
                    ELSE 0
                END,
            slider_finishing_stock = slider_finishing_stock + 
                CASE 
                    WHEN OLD.section = 'finishing' THEN OLD.production_quantity
                    ELSE 0
                END
        WHERE od.uuid = od_uuid;

    ELSIF lower(item_name) = 'vislon' THEN
        UPDATE zipper.order_description od
        SET 
            tape_transferred = tape_transferred + 
                CASE 
                    WHEN OLD.section = 'teeth_molding' THEN 
                        CASE
                            WHEN OLD.production_quantity_in_kg = 0 THEN OLD.production_quantity + OLD.wastage 
                            ELSE OLD.production_quantity_in_kg + OLD.wastage 
                        END
                    ELSE 0
                END,
            slider_finishing_stock = slider_finishing_stock + 
                CASE 
                    WHEN OLD.section = 'finishing' THEN OLD.production_quantity
                    ELSE 0
                END
        WHERE od.uuid = od_uuid;

    ELSIF lower(item_name) = 'nylon' AND lower(nylon_stopper_name) = 'plastic' THEN
        UPDATE zipper.order_description od
        SET 
            tape_transferred = tape_transferred + 
                CASE 
                    WHEN OLD.section = 'finishing' THEN OLD.production_quantity_in_kg + OLD.wastage 
                    ELSE 
                        CASE
                            WHEN OLD.production_quantity_in_kg = 0 THEN OLD.production_quantity + OLD.wastage 
                            ELSE OLD.production_quantity_in_kg + OLD.wastage 
                        END 
                END,
            slider_finishing_stock = slider_finishing_stock + 
                CASE 
                    WHEN OLD.section = 'finishing' THEN OLD.production_quantity
                    ELSE 0
                END
        WHERE od.uuid = od_uuid;

    ELSIF lower(item_name) = 'nylon' AND lower(nylon_stopper_name) = 'metallic' THEN
        UPDATE zipper.order_description od
        SET 
            tape_transferred = tape_transferred + 
                CASE 
                    WHEN OLD.section = 'finishing' THEN OLD.production_quantity_in_kg + OLD.wastage 
                    ELSE 
                        CASE
                            WHEN OLD.production_quantity_in_kg = 0 THEN OLD.production_quantity + OLD.wastage 
                            ELSE OLD.production_quantity_in_kg + OLD.wastage 
                        END 
                END,
            slider_finishing_stock = slider_finishing_stock + 
                CASE 
                    WHEN OLD.section = 'finishing' THEN OLD.production_quantity 
                    ELSE 0
                END
        WHERE od.uuid = od_uuid;
    END IF;

    -- Update sfg table
    UPDATE zipper.sfg sfg
    SET 
        teeth_molding_prod = teeth_molding_prod - 
            CASE 
                WHEN OLD.section = 'teeth_molding' THEN 
                    CASE WHEN lower(vodf.item_name) = 'metal' 
                    THEN OLD.production_quantity 
                    ELSE
                        CASE
                            WHEN OLD.production_quantity_in_kg = 0 THEN OLD.production_quantity 
                            ELSE OLD.production_quantity_in_kg 
                        END 
                    END
                ELSE 0
            END,
        finishing_stock = finishing_stock + 
            CASE 
                WHEN OLD.section = 'finishing' THEN 
                    CASE
                        WHEN OLD.production_quantity_in_kg = 0 THEN OLD.production_quantity + OLD.wastage 
                        ELSE OLD.production_quantity_in_kg + OLD.wastage 
                    END 
                ELSE 0
            END 
            - 
            CASE 
                WHEN OLD.section = 'teeth_coloring' THEN OLD.production_quantity 
                ELSE 0 
            END,
        finishing_prod = finishing_prod - 
            CASE 
                WHEN OLD.section = 'finishing' THEN OLD.production_quantity 
                ELSE 0
            END,
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
                WHEN OLD.section = 'dying_and_iron' THEN OLD.production_quantity 
                ELSE 0 
            END,
        -- teeth_coloring_prod = teeth_coloring_prod - 
        --     CASE 
        --         WHEN OLD.section = 'teeth_coloring' THEN OLD.production_quantity 
        --         ELSE 0 
        --     END,
        coloring_prod = coloring_prod - 
            CASE 
                WHEN OLD.section = 'coloring' THEN OLD.production_quantity
                ELSE 0 
            END
    FROM zipper.order_entry oe
    LEFT JOIN zipper.v_order_details_full vodf ON vodf.order_description_uuid = oe.order_description_uuid
    WHERE sfg.uuid = OLD.sfg_uuid AND sfg.order_entry_uuid = oe.uuid AND oe.order_description_uuid = od_uuid;

    RETURN OLD;
END;
$$;
 A   DROP FUNCTION zipper.sfg_after_sfg_production_delete_function();
       zipper          postgres    false    15            �           1255    18000 *   sfg_after_sfg_production_insert_function()    FUNCTION     �  CREATE FUNCTION zipper.sfg_after_sfg_production_insert_function() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
DECLARE 
    item_name TEXT;
    od_uuid TEXT;
    nylon_stopper_name TEXT;
BEGIN
    -- Fetch item_name and order_description_uuid once
    SELECT vodf.item_name, oe.order_description_uuid, vodf.nylon_stopper_name INTO item_name, od_uuid, nylon_stopper_name
    FROM zipper.sfg sfg
    LEFT JOIN zipper.order_entry oe ON oe.uuid = sfg.order_entry_uuid
    LEFT JOIN zipper.v_order_details_full vodf ON oe.order_description_uuid = vodf.order_description_uuid
    WHERE sfg.uuid = NEW.sfg_uuid;

    -- Update order_description based on item_name
    IF lower(item_name) = 'metal' THEN
        UPDATE zipper.order_description od
        SET 
            tape_transferred = tape_transferred - 
                CASE 
                    WHEN NEW.section = 'teeth_molding' THEN NEW.production_quantity_in_kg + NEW.wastage 
                    ELSE 0
                END,
            slider_finishing_stock = slider_finishing_stock - 
                CASE 
                    WHEN NEW.section = 'finishing' THEN NEW.production_quantity
                    ELSE 0
                END
        WHERE od.uuid = od_uuid;

    ELSIF lower(item_name) = 'vislon' THEN
        UPDATE zipper.order_description od
        SET 
            tape_transferred = tape_transferred - 
                CASE 
                    WHEN NEW.section = 'teeth_molding' THEN 
                        CASE
                            WHEN NEW.production_quantity_in_kg = 0 THEN NEW.production_quantity + NEW.wastage 
                            ELSE NEW.production_quantity_in_kg + NEW.wastage 
                        END
                    ELSE 0
                END,
            slider_finishing_stock = slider_finishing_stock -
                CASE 
                    WHEN NEW.section = 'finishing' THEN NEW.production_quantity 
                    ELSE 0
                END
        WHERE od.uuid = od_uuid;

    ELSIF lower(item_name) = 'nylon' AND lower(nylon_stopper_name) = 'plastic' THEN
        UPDATE zipper.order_description od
        SET 
            tape_transferred = tape_transferred - 
                CASE 
                    WHEN NEW.section = 'finishing' THEN NEW.production_quantity_in_kg + NEW.wastage 
                    ELSE 
                        CASE
                            WHEN NEW.production_quantity_in_kg = 0 THEN NEW.production_quantity + NEW.wastage 
                            ELSE NEW.production_quantity_in_kg + NEW.wastage 
                        END 
                END,
            slider_finishing_stock = slider_finishing_stock -
                CASE 
                    WHEN NEW.section = 'finishing' THEN NEW.production_quantity
                    ELSE 0
                END
        WHERE od.uuid = od_uuid;

    ELSIF lower(item_name) = 'nylon' AND lower(nylon_stopper_name) = 'metallic' THEN
        UPDATE zipper.order_description od
        SET 
            tape_transferred = tape_transferred - 
                CASE 
                    WHEN NEW.section = 'finishing' THEN NEW.production_quantity_in_kg + NEW.wastage 
                    ELSE 
                        CASE
                            WHEN NEW.production_quantity_in_kg = 0 THEN NEW.production_quantity + NEW.wastage 
                            ELSE NEW.production_quantity_in_kg + NEW.wastage 
                        END 
                END,
            slider_finishing_stock = slider_finishing_stock -
                CASE 
                    WHEN NEW.section = 'finishing' THEN NEW.production_quantity 
                    ELSE 0
                END
        WHERE od.uuid = od_uuid;
    END IF;

    -- Update sfg table
    UPDATE zipper.sfg sfg
    SET 
        teeth_molding_prod = teeth_molding_prod + 
            CASE 
                WHEN NEW.section = 'teeth_molding' THEN 
                    CASE WHEN lower(vodf.item_name) = 'metal' 
                    THEN NEW.production_quantity 
                    ELSE 
                        CASE
                            WHEN NEW.production_quantity_in_kg = 0 THEN NEW.production_quantity 
                            ELSE NEW.production_quantity_in_kg 
                        END 
                    END
                ELSE 0
            END,
        finishing_stock = finishing_stock - 
            CASE 
                WHEN NEW.section = 'finishing' THEN 
                    CASE
                        WHEN NEW.production_quantity_in_kg = 0 THEN NEW.production_quantity + NEW.wastage 
                        ELSE NEW.production_quantity_in_kg + NEW.wastage 
                    END 
                ELSE 0
            END 
            + 
            CASE 
                WHEN NEW.section = 'teeth_coloring' THEN NEW.production_quantity 
                ELSE 0 
            END,
        finishing_prod = finishing_prod +
            CASE 
                WHEN NEW.section = 'finishing' THEN NEW.production_quantity 
                ELSE 0
            END,
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
                WHEN NEW.section = 'dying_and_iron' THEN NEW.production_quantity 
                ELSE 0 
            END,
        -- teeth_coloring_prod = teeth_coloring_prod + 
        --     CASE 
        --         WHEN NEW.section = 'teeth_coloring' THEN NEW.production_quantity 
        --         ELSE 0 
        --     END,
        coloring_prod = coloring_prod + 
            CASE 
                WHEN NEW.section = 'coloring' THEN NEW.production_quantity
                ELSE 0 
            END
    FROM zipper.order_entry oe
    LEFT JOIN zipper.v_order_details_full vodf ON vodf.order_description_uuid = oe.order_description_uuid
    WHERE sfg.uuid = NEW.sfg_uuid AND sfg.order_entry_uuid = oe.uuid AND oe.order_description_uuid = od_uuid;

    RETURN NEW;
END;
$$;
 A   DROP FUNCTION zipper.sfg_after_sfg_production_insert_function();
       zipper          postgres    false    15            O           1255    18001 *   sfg_after_sfg_production_update_function()    FUNCTION     D  CREATE FUNCTION zipper.sfg_after_sfg_production_update_function() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
DECLARE 
    item_name TEXT;
    od_uuid TEXT;
    nylon_stopper_name TEXT;
BEGIN
    -- Fetch item_name and order_description_uuid once
    SELECT vodf.item_name, oe.order_description_uuid, vodf.nylon_stopper_name INTO item_name, od_uuid, nylon_stopper_name
    FROM zipper.sfg sfg
    LEFT JOIN zipper.order_entry oe ON oe.uuid = sfg.order_entry_uuid
    LEFT JOIN zipper.v_order_details_full vodf ON oe.order_description_uuid = vodf.order_description_uuid
    WHERE sfg.uuid = NEW.sfg_uuid;

    -- Update order_description based on item_name
    IF lower(item_name) = 'metal' THEN
        UPDATE zipper.order_description od
        SET 
            tape_transferred = tape_transferred - 
                CASE 
                    WHEN NEW.section = 'teeth_molding' THEN (NEW.production_quantity_in_kg + NEW.wastage) - (OLD.production_quantity_in_kg + OLD.wastage)
                    ELSE 0
                END,
            slider_finishing_stock = slider_finishing_stock - 
                CASE 
                    WHEN NEW.section = 'finishing' THEN (NEW.production_quantity) - (OLD.production_quantity)
                    ELSE 0
                END
        WHERE od.uuid = od_uuid;

    ELSIF lower(item_name) = 'vislon' THEN
        UPDATE zipper.order_description od
        SET 
            tape_transferred = tape_transferred - 
                CASE 
                    WHEN NEW.section = 'teeth_molding' THEN 
                        CASE
                            WHEN NEW.production_quantity_in_kg = 0 THEN (NEW.production_quantity + NEW.wastage) - (OLD.production_quantity + OLD.wastage)
                            ELSE (NEW.production_quantity_in_kg + NEW.wastage) - (OLD.production_quantity_in_kg + OLD.wastage)
                        END
                    ELSE 0
                END,
            slider_finishing_stock = slider_finishing_stock - 
                CASE 
                    WHEN NEW.section = 'finishing' THEN (NEW.production_quantity) - (OLD.production_quantity)
                    ELSE 0
                END
        WHERE od.uuid = od_uuid;

    ELSIF lower(item_name) = 'nylon' AND lower(nylon_stopper_name) = 'plastic' THEN
        UPDATE zipper.order_description od
        SET 
            tape_transferred = tape_transferred - 
                CASE 
                    WHEN NEW.section = 'finishing' THEN (NEW.production_quantity_in_kg + NEW.wastage) - (OLD.production_quantity_in_kg + OLD.wastage)
                    ELSE 
                        CASE
                            WHEN NEW.production_quantity_in_kg = 0 THEN (NEW.production_quantity + NEW.wastage) - (OLD.production_quantity + OLD.wastage)
                            ELSE (NEW.production_quantity_in_kg + NEW.wastage) - (OLD.production_quantity_in_kg + OLD.wastage)
                        END 
                END,
            slider_finishing_stock = slider_finishing_stock - 
                CASE 
                    WHEN NEW.section = 'finishing' THEN (NEW.production_quantity) - (OLD.production_quantity)
                    ELSE 0
                END
        WHERE od.uuid = od_uuid;

    ELSIF lower(item_name) = 'nylon' AND lower(nylon_stopper_name) = 'metallic' THEN
        UPDATE zipper.order_description od
        SET 
            tape_transferred = tape_transferred - 
                CASE 
                    WHEN NEW.section = 'finishing' THEN (NEW.production_quantity_in_kg + NEW.wastage) - (OLD.production_quantity_in_kg + OLD.wastage)
                    ELSE 
                        CASE
                            WHEN NEW.production_quantity_in_kg = 0 THEN (NEW.production_quantity + NEW.wastage) - (OLD.production_quantity + OLD.wastage)
                            ELSE (NEW.production_quantity_in_kg + NEW.wastage) - (OLD.production_quantity_in_kg + OLD.wastage)
                        END 
                END,
            slider_finishing_stock = slider_finishing_stock - 
                CASE 
                    WHEN NEW.section = 'finishing' THEN (NEW.production_quantity) - (OLD.production_quantity)
                    ELSE 0
                END
        WHERE od.uuid = od_uuid;
    END IF;

    -- Update sfg table
    UPDATE zipper.sfg sfg
    SET 
        teeth_molding_prod = teeth_molding_prod + 
            CASE 
                WHEN NEW.section = 'teeth_molding' THEN 
                    CASE WHEN lower(vodf.item_name) = 'metal' 
                    THEN NEW.production_quantity - OLD.production_quantity 
                    ELSE
                        CASE
                            WHEN NEW.production_quantity_in_kg = 0 THEN NEW.production_quantity - OLD.production_quantity
                            ELSE NEW.production_quantity_in_kg - OLD.production_quantity_in_kg
                        END 
                    END
                ELSE 0
            END,
        finishing_stock = finishing_stock - 
            CASE 
                WHEN NEW.section = 'finishing' THEN 
                    CASE
                        WHEN NEW.production_quantity_in_kg = 0 THEN (NEW.production_quantity + NEW.wastage) - (OLD.production_quantity + OLD.wastage)
                        ELSE (NEW.production_quantity_in_kg + NEW.wastage) - (OLD.production_quantity_in_kg + OLD.wastage)
                    END 
                ELSE 0
            END 
            + 
            CASE 
                WHEN NEW.section = 'teeth_coloring' THEN NEW.production_quantity - OLD.production_quantity
                ELSE 0 
            END,
        finishing_prod = finishing_prod + 
            CASE 
                WHEN NEW.section = 'finishing' THEN NEW.production_quantity - OLD.production_quantity
                ELSE 0
            END,
        teeth_coloring_stock = teeth_coloring_stock - 
            CASE 
                WHEN NEW.section = 'teeth_coloring' THEN 
                    CASE 
                        WHEN NEW.production_quantity_in_kg = 0 THEN (NEW.production_quantity + NEW.wastage) - (OLD.production_quantity + OLD.wastage)
                        ELSE (NEW.production_quantity_in_kg + NEW.wastage) - (OLD.production_quantity_in_kg + OLD.wastage)
                    END 
                ELSE 0 
            END,
        dying_and_iron_prod = dying_and_iron_prod + 
            CASE 
                WHEN NEW.section = 'dying_and_iron' THEN NEW.production_quantity - OLD.production_quantity
                ELSE 0 
            END,
        -- teeth_coloring_prod = teeth_coloring_prod + 
        --     CASE 
        --         WHEN NEW.section = 'teeth_coloring' THEN NEW.production_quantity - OLD.production_quantity
        --         ELSE 0 
        --     END,
        coloring_prod = coloring_prod + 
            CASE 
                WHEN NEW.section = 'coloring' THEN NEW.production_quantity - OLD.production_quantity
                ELSE 0 
            END
    FROM zipper.order_entry oe
    LEFT JOIN zipper.v_order_details_full vodf ON vodf.order_description_uuid = oe.order_description_uuid
    WHERE sfg.uuid = NEW.sfg_uuid AND sfg.order_entry_uuid = oe.uuid AND oe.order_description_uuid = od_uuid;

    RETURN NEW;
END;
$$;
 A   DROP FUNCTION zipper.sfg_after_sfg_production_update_function();
       zipper          postgres    false    15            ~           1255    49154 +   sfg_after_sfg_transaction_delete_function()    FUNCTION     (  CREATE FUNCTION zipper.sfg_after_sfg_transaction_delete_function() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
DECLARE
    tocs_uuid INT;
BEGIN
    -- Updating stocks based on OLD.trx_to
    UPDATE zipper.sfg
     SET
        teeth_molding_stock = teeth_molding_stock 
            - CASE WHEN OLD.trx_to = 'teeth_molding_stock' THEN 
            CASE WHEN OLD.trx_quantity_in_kg = 0 THEN OLD.trx_quantity ELSE OLD.trx_quantity_in_kg END ELSE 0 END,
        teeth_coloring_stock = teeth_coloring_stock 
            - CASE WHEN OLD.trx_to = 'teeth_coloring_stock' THEN 
            CASE WHEN OLD.trx_quantity_in_kg = 0 THEN OLD.trx_quantity ELSE OLD.trx_quantity_in_kg END ELSE 0 END,
        finishing_stock = finishing_stock 
            - CASE WHEN OLD.trx_to = 'finishing_stock' THEN 
            CASE WHEN OLD.trx_quantity_in_kg = 0 THEN OLD.trx_quantity ELSE OLD.trx_quantity_in_kg END ELSE 0 END,
        warehouse = warehouse 
            - CASE WHEN OLD.trx_to = 'warehouse' THEN 
            CASE WHEN OLD.trx_quantity_in_kg = 0 THEN OLD.trx_quantity ELSE OLD.trx_quantity_in_kg END ELSE 0 END
    WHERE uuid = OLD.sfg_uuid;

    -- Updating productions based on OLD.trx_from
    UPDATE zipper.sfg SET
        teeth_molding_prod = teeth_molding_prod + 
        CASE WHEN OLD.trx_from = 'teeth_molding_prod' THEN CASE WHEN OLD.trx_quantity_in_kg = 0 THEN OLD.trx_quantity ELSE OLD.trx_quantity_in_kg END ELSE 0 END,

        teeth_coloring_prod = teeth_coloring_prod + 
        CASE WHEN OLD.trx_from = 'teeth_coloring_prod' THEN CASE WHEN OLD.trx_quantity_in_kg = 0 THEN OLD.trx_quantity ELSE OLD.trx_quantity_in_kg END ELSE 0 END,

        finishing_prod = finishing_prod + 
        CASE WHEN OLD.trx_from = 'finishing_prod' THEN CASE WHEN OLD.trx_quantity_in_kg = 0 THEN OLD.trx_quantity ELSE OLD.trx_quantity_in_kg END ELSE 0 END,

        warehouse = warehouse + 
        CASE WHEN OLD.trx_from = 'warehouse' THEN CASE WHEN OLD.trx_quantity_in_kg = 0 THEN OLD.trx_quantity ELSE OLD.trx_quantity_in_kg END ELSE 0 END
    WHERE uuid = OLD.sfg_uuid;

    RETURN OLD;
END;
$$;
 B   DROP FUNCTION zipper.sfg_after_sfg_transaction_delete_function();
       zipper          postgres    false    15            B           1255    18003 +   sfg_after_sfg_transaction_insert_function()    FUNCTION     *  CREATE FUNCTION zipper.sfg_after_sfg_transaction_insert_function() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
DECLARE
    tocs_uuid INT;
BEGIN
    -- Updating stocks based on NEW.trx_to
    UPDATE zipper.sfg SET
        teeth_molding_stock = teeth_molding_stock + 
        CASE WHEN NEW.trx_to = 'teeth_molding_stock' THEN 
        CASE WHEN NEW.trx_quantity_in_kg = 0 THEN NEW.trx_quantity ELSE NEW.trx_quantity_in_kg END ELSE 0 END,

        teeth_coloring_stock = teeth_coloring_stock + 
        CASE WHEN NEW.trx_to = 'teeth_coloring_stock' THEN 
        CASE WHEN NEW.trx_quantity_in_kg = 0 THEN NEW.trx_quantity ELSE NEW.trx_quantity_in_kg END ELSE 0 END,

        finishing_stock = finishing_stock + 
        CASE WHEN NEW.trx_to = 'finishing_stock' THEN 
        CASE WHEN NEW.trx_quantity_in_kg = 0 THEN NEW.trx_quantity ELSE NEW.trx_quantity_in_kg END ELSE 0 END,

        warehouse = warehouse + 
        CASE WHEN NEW.trx_to = 'warehouse' THEN 
        CASE WHEN NEW.trx_quantity_in_kg = 0 THEN NEW.trx_quantity ELSE NEW.trx_quantity_in_kg END ELSE 0 END
    WHERE uuid = NEW.sfg_uuid;

    -- Updating productions based on NEW.trx_from
    UPDATE zipper.sfg SET
        teeth_molding_prod = teeth_molding_prod - 
        CASE WHEN NEW.trx_from = 'teeth_molding_prod' THEN 
        CASE WHEN NEW.trx_quantity_in_kg = 0 THEN NEW.trx_quantity ELSE NEW.trx_quantity_in_kg END ELSE 0 END,

        teeth_coloring_prod = teeth_coloring_prod - 
        CASE WHEN NEW.trx_from = 'teeth_coloring_prod' THEN 
        CASE WHEN NEW.trx_quantity_in_kg = 0 THEN NEW.trx_quantity ELSE NEW.trx_quantity_in_kg END ELSE 0 END,

        finishing_prod = finishing_prod - 
        CASE WHEN NEW.trx_from = 'finishing_prod' THEN 
        CASE WHEN NEW.trx_quantity_in_kg = 0 THEN NEW.trx_quantity ELSE NEW.trx_quantity_in_kg END ELSE 0 END,

        warehouse = warehouse - 
        CASE WHEN NEW.trx_from = 'warehouse' THEN 
        CASE WHEN NEW.trx_quantity_in_kg = 0 THEN NEW.trx_quantity ELSE NEW.trx_quantity_in_kg END ELSE 0 END
    WHERE uuid = NEW.sfg_uuid;

    RETURN NEW;
END;
$$;
 B   DROP FUNCTION zipper.sfg_after_sfg_transaction_insert_function();
       zipper          postgres    false    15            �           1255    49155 +   sfg_after_sfg_transaction_update_function()    FUNCTION     ?  CREATE FUNCTION zipper.sfg_after_sfg_transaction_update_function() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
DECLARE
    tocs_uuid INT;
BEGIN
    -- Updating stocks based on OLD.trx_to and NEW.trx_to
    UPDATE zipper.sfg SET
        teeth_molding_stock = teeth_molding_stock 
            - CASE WHEN OLD.trx_to = 'teeth_molding_stock' THEN CASE WHEN OLD.trx_quantity_in_kg = 0 THEN OLD.trx_quantity ELSE OLD.trx_quantity_in_kg END ELSE 0 END
            + CASE WHEN NEW.trx_to = 'teeth_molding_stock' THEN CASE WHEN NEW.trx_quantity_in_kg = 0 THEN NEW.trx_quantity ELSE NEW.trx_quantity_in_kg END ELSE 0 END,
        teeth_coloring_stock = teeth_coloring_stock 
            - CASE WHEN OLD.trx_to = 'teeth_coloring_stock' THEN CASE WHEN OLD.trx_quantity_in_kg = 0 THEN OLD.trx_quantity ELSE OLD.trx_quantity_in_kg END ELSE 0 END
            + CASE WHEN NEW.trx_to = 'teeth_coloring_stock' THEN CASE WHEN NEW.trx_quantity_in_kg = 0 THEN NEW.trx_quantity ELSE NEW.trx_quantity_in_kg END ELSE 0 END,
        finishing_stock = finishing_stock 
            - CASE WHEN OLD.trx_to = 'finishing_stock' THEN CASE WHEN OLD.trx_quantity_in_kg = 0 THEN OLD.trx_quantity ELSE OLD.trx_quantity_in_kg END ELSE 0 END
            + CASE WHEN NEW.trx_to = 'finishing_stock' THEN CASE WHEN NEW.trx_quantity_in_kg = 0 THEN NEW.trx_quantity ELSE NEW.trx_quantity_in_kg END ELSE 0 END,
        warehouse = warehouse 
            - CASE WHEN OLD.trx_to = 'warehouse' THEN CASE WHEN OLD.trx_quantity_in_kg = 0 THEN OLD.trx_quantity ELSE OLD.trx_quantity_in_kg END ELSE 0 END
            + CASE WHEN NEW.trx_to = 'warehouse' THEN CASE WHEN NEW.trx_quantity_in_kg = 0 THEN NEW.trx_quantity ELSE NEW.trx_quantity_in_kg END ELSE 0 END
    WHERE uuid = NEW.sfg_uuid;

    -- Updating productions based on OLD.trx_from and NEW.trx_from
    UPDATE zipper.sfg SET
        teeth_molding_prod = teeth_molding_prod 
            + CASE WHEN OLD.trx_from = 'teeth_molding_prod' THEN CASE WHEN OLD.trx_quantity_in_kg = 0 THEN OLD.trx_quantity ELSE OLD.trx_quantity_in_kg END ELSE 0 END
            - CASE WHEN NEW.trx_from = 'teeth_molding_prod' THEN CASE WHEN NEW.trx_quantity_in_kg = 0 THEN NEW.trx_quantity ELSE NEW.trx_quantity_in_kg END ELSE 0 END,
        teeth_coloring_prod = teeth_coloring_prod 
            + CASE WHEN OLD.trx_from = 'teeth_coloring_prod' THEN CASE WHEN OLD.trx_quantity_in_kg = 0 THEN OLD.trx_quantity ELSE OLD.trx_quantity_in_kg END ELSE 0 END
            - CASE WHEN NEW.trx_from = 'teeth_coloring_prod' THEN CASE WHEN NEW.trx_quantity_in_kg = 0 THEN NEW.trx_quantity ELSE NEW.trx_quantity_in_kg END ELSE 0 END,
        finishing_prod = finishing_prod 
            + CASE WHEN OLD.trx_from = 'finishing_prod' THEN CASE WHEN OLD.trx_quantity_in_kg = 0 THEN OLD.trx_quantity ELSE OLD.trx_quantity_in_kg END ELSE 0 END
            - CASE WHEN NEW.trx_from = 'finishing_prod' THEN CASE WHEN NEW.trx_quantity_in_kg = 0 THEN NEW.trx_quantity ELSE NEW.trx_quantity_in_kg END ELSE 0 END,
        warehouse = warehouse 
            + CASE WHEN OLD.trx_from = 'warehouse' THEN CASE WHEN OLD.trx_quantity_in_kg = 0 THEN OLD.trx_quantity ELSE OLD.trx_quantity_in_kg END ELSE 0 END
            - CASE WHEN NEW.trx_from = 'warehouse' THEN CASE WHEN NEW.trx_quantity_in_kg = 0 THEN NEW.trx_quantity ELSE NEW.trx_quantity_in_kg END ELSE 0 END
        WHERE uuid = NEW.sfg_uuid;
    
    RETURN NEW;
END;
$$;
 B   DROP FUNCTION zipper.sfg_after_sfg_transaction_update_function();
       zipper          postgres    false    15            g           1255    18005 A   stock_after_material_trx_against_order_description_delete_funct()    FUNCTION     =  CREATE FUNCTION zipper.stock_after_material_trx_against_order_description_delete_funct() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    -- Update material,stock
    UPDATE material.stock
    SET
        stock = stock + OLD.trx_quantity
    WHERE material_uuid = OLD.material_uuid;

    RETURN OLD;
END;
$$;
 X   DROP FUNCTION zipper.stock_after_material_trx_against_order_description_delete_funct();
       zipper          postgres    false    15            y           1255    18006 A   stock_after_material_trx_against_order_description_insert_funct()    FUNCTION     =  CREATE FUNCTION zipper.stock_after_material_trx_against_order_description_insert_funct() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    -- Update material,stock
    UPDATE material.stock
    SET
        stock = stock - NEW.trx_quantity
    WHERE material_uuid = NEW.material_uuid;

    RETURN NEW;
END;
$$;
 X   DROP FUNCTION zipper.stock_after_material_trx_against_order_description_insert_funct();
       zipper          postgres    false    15            �           1255    18007 A   stock_after_material_trx_against_order_description_update_funct()    FUNCTION     i  CREATE FUNCTION zipper.stock_after_material_trx_against_order_description_update_funct() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    -- Update material,stock
    UPDATE material.stock
    SET
        stock = stock 
            - NEW.trx_quantity
            + OLD.trx_quantity
    WHERE material_uuid = NEW.material_uuid;

    RETURN NEW;
END;
$$;
 X   DROP FUNCTION zipper.stock_after_material_trx_against_order_description_update_funct();
       zipper          postgres    false    15            �           1255    18008 &   tape_coil_after_tape_coil_production()    FUNCTION     �  CREATE FUNCTION zipper.tape_coil_after_tape_coil_production() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    --Update zipper.tape_coil table
    UPDATE zipper.tape_coil 
    SET
        -- Tape Production
        quantity = quantity 
        + CASE WHEN NEW.section = 'tape' THEN NEW.production_quantity ELSE 0 END,

        -- Coil Production
        trx_quantity_in_coil = trx_quantity_in_coil 
        - CASE WHEN NEW.section = 'coil' THEN NEW.production_quantity + NEW.wastage ELSE 0 END,
        quantity_in_coil = quantity_in_coil
        + CASE WHEN NEW.section = 'coil' THEN NEW.production_quantity ELSE 0 END,

        -- Tape Or Production for Stock
        trx_quantity_in_dying = trx_quantity_in_dying
        - CASE WHEN NEW.section = 'stock' THEN NEW.production_quantity + NEW.wastage ELSE 0 END,
        stock_quantity = stock_quantity 
        + CASE WHEN NEW.section = 'stock' THEN NEW.production_quantity ELSE 0 END

    WHERE uuid = NEW.tape_coil_uuid;

    RETURN NEW;
END;
$$;
 =   DROP FUNCTION zipper.tape_coil_after_tape_coil_production();
       zipper          postgres    false    15            F           1255    18009 -   tape_coil_after_tape_coil_production_delete()    FUNCTION     �  CREATE FUNCTION zipper.tape_coil_after_tape_coil_production_delete() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    -- Update zipper.tape_coil table
    UPDATE zipper.tape_coil 
    SET
        -- Tape Production
        quantity = quantity 
        - CASE WHEN OLD.section = 'tape' THEN OLD.production_quantity ELSE 0 END,

        -- Coil Production
        trx_quantity_in_coil = trx_quantity_in_coil 
        + CASE WHEN OLD.section = 'coil' THEN OLD.production_quantity + OLD.wastage ELSE 0 END,
        quantity_in_coil = quantity_in_coil
        - CASE WHEN OLD.section = 'coil' THEN OLD.production_quantity ELSE 0 END,

        -- Tape Or Production for Stock
        trx_quantity_in_dying = trx_quantity_in_dying
        + CASE WHEN OLD.section = 'stock' THEN OLD.production_quantity  + OLD.wastage ELSE 0 END,
        stock_quantity = stock_quantity 
        - CASE WHEN OLD.section = 'stock' THEN OLD.production_quantity ELSE 0 END

    WHERE uuid = OLD.tape_coil_uuid;

    RETURN OLD;
END;
$$;
 D   DROP FUNCTION zipper.tape_coil_after_tape_coil_production_delete();
       zipper          postgres    false    15            q           1255    18010 -   tape_coil_after_tape_coil_production_update()    FUNCTION     �  CREATE FUNCTION zipper.tape_coil_after_tape_coil_production_update() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    -- Update zipper.tape_coil table
    UPDATE zipper.tape_coil 
    SET
        -- Tape Production
        quantity = quantity 
        + CASE WHEN OLD.section = 'tape' THEN OLD.production_quantity ELSE 0 END
        - CASE WHEN NEW.section = 'tape' THEN NEW.production_quantity ELSE 0 END,

        -- Coil Production
        trx_quantity_in_coil = trx_quantity_in_coil 
        + CASE WHEN OLD.section = 'coil' THEN OLD.production_quantity + OLD.wastage ELSE 0 END
        - CASE WHEN NEW.section = 'coil' THEN NEW.production_quantity + NEW.wastage ELSE 0 END,

        quantity_in_coil = quantity_in_coil
        - CASE WHEN OLD.section = 'coil' THEN OLD.production_quantity ELSE 0 END
        + CASE WHEN NEW.section = 'coil' THEN NEW.production_quantity ELSE 0 END,

        -- Tape Or Production for Stock
        trx_quantity_in_dying = trx_quantity_in_dying
        + CASE WHEN OLD.section = 'stock' THEN OLD.production_quantity + OLD.wastage ELSE 0 END
        - CASE WHEN NEW.section = 'stock' THEN NEW.production_quantity + NEW.wastage ELSE 0 END,

        stock_quantity = stock_quantity 
        - CASE WHEN OLD.section = 'stock' THEN OLD.production_quantity ELSE 0 END
        + CASE WHEN NEW.section = 'stock' THEN NEW.production_quantity ELSE 0 END

    WHERE uuid = NEW.tape_coil_uuid;

    RETURN NEW;
END;
$$;
 D   DROP FUNCTION zipper.tape_coil_after_tape_coil_production_update();
       zipper          postgres    false    15            b           1255    81964 !   tape_coil_after_tape_trx_delete()    FUNCTION     �  CREATE FUNCTION zipper.tape_coil_after_tape_trx_delete() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    -- Update zipper.tape_coil table
    UPDATE zipper.tape_coil 
    SET
        -- Tape Trx to Coil Or Dyeing
        quantity = quantity + CASE WHEN OLD.to_section = 'dyeing' OR OLD.to_section = 'coil' THEN OLD.trx_quantity ELSE 0 END,
        -- Coil To Dyeing
        quantity_in_coil = quantity_in_coil + CASE WHEN OLD.to_section = 'coil_dyeing' AND (SELECT lower(name) FROM public.properties WHERE zipper.tape_coil.item_uuid = public.properties.uuid) = 'nylon' THEN OLD.trx_quantity ELSE 0 END,
        -- Tape AND Coil Dyeing Trx
        trx_quantity_in_dying = trx_quantity_in_dying 
        - CASE WHEN OLD.to_section = 'dyeing' OR OLD.to_section = 'coil_dyeing' THEN OLD.trx_quantity ELSE 0 END
        + CASE WHEN OLD.to_section = 'stock' THEN OLD.trx_quantity ELSE 0 END,
        -- Tape to Coil Trx 
        trx_quantity_in_coil = trx_quantity_in_coil - CASE WHEN OLD.to_section = 'coil' THEN OLD.trx_quantity ELSE 0 END,
        -- Dyed Tape or Coil Stock
        stock_quantity = stock_quantity - CASE WHEN OLD.to_section = 'stock' THEN OLD.trx_quantity ELSE 0 END
    WHERE uuid = OLD.tape_coil_uuid;
    RETURN OLD;
END;
$$;
 8   DROP FUNCTION zipper.tape_coil_after_tape_trx_delete();
       zipper          postgres    false    15            �           1255    81963 !   tape_coil_after_tape_trx_insert()    FUNCTION     �  CREATE FUNCTION zipper.tape_coil_after_tape_trx_insert() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    --Update zipper.tape_coil table
    UPDATE zipper.tape_coil 
    SET
        -- Tape Trx to Coil Or Dyeing
        quantity = quantity - CASE WHEN NEW.to_section = 'dyeing' OR NEW.to_section = 'coil' THEN NEW.trx_quantity ELSE 0 END,
        -- Coil To Dyeing
        quantity_in_coil = quantity_in_coil 
        - CASE WHEN NEW.to_section = 'coil_dyeing' AND (SELECT lower(name) FROM public.properties where zipper.tape_coil.item_uuid = public.properties.uuid) = 'nylon' THEN NEW.trx_quantity ELSE 0 END,
        -- Tape AND Coil Dyeing Trx
        trx_quantity_in_dying = trx_quantity_in_dying 
        + CASE WHEN NEW.to_section = 'dyeing' OR NEW.to_section = 'coil_dyeing' THEN NEW.trx_quantity ELSE 0 END 
        - CASE WHEN NEW.to_section = 'stock' THEN NEW.trx_quantity ELSE 0 END,
        
        -- Tape to Coil Trx 
        trx_quantity_in_coil = trx_quantity_in_coil + CASE WHEN NEW.to_section = 'coil' THEN NEW.trx_quantity ELSE 0 END,

        -- Dyed Tape or Coil Stock
        stock_quantity = stock_quantity + CASE WHEN NEW.to_section = 'stock' THEN NEW.trx_quantity ELSE 0 END

    WHERE uuid = NEW.tape_coil_uuid;
RETURN NEW;
END;
$$;
 8   DROP FUNCTION zipper.tape_coil_after_tape_trx_insert();
       zipper          postgres    false    15            Q           1255    81965 !   tape_coil_after_tape_trx_update()    FUNCTION     �  CREATE FUNCTION zipper.tape_coil_after_tape_trx_update() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    -- Update zipper.tape_coil table
    UPDATE zipper.tape_coil 
    SET
        -- Tape Trx to Coil Or Dyeing
        quantity = quantity - CASE 
            WHEN NEW.to_section = 'dyeing' OR NEW.to_section = 'coil' THEN NEW.trx_quantity 
            ELSE 0 
        END + CASE 
            WHEN OLD.to_section = 'dyeing' OR OLD.to_section = 'coil' THEN OLD.trx_quantity 
            ELSE 0 
        END,
        -- Coil To Dyeing
        quantity_in_coil = quantity_in_coil - CASE 
            WHEN NEW.to_section = 'coil_dyeing' AND (SELECT lower(name) FROM public.properties WHERE zipper.tape_coil.item_uuid = public.properties.uuid) = 'nylon' THEN NEW.trx_quantity 
            ELSE 0 
        END + CASE 
            WHEN OLD.to_section = 'coil_dyeing' AND (SELECT lower(name) FROM public.properties WHERE zipper.tape_coil.item_uuid = public.properties.uuid) = 'nylon' THEN OLD.trx_quantity 
            ELSE 0 
        END,
        -- Tape AND Coil Dyeing Trx
        trx_quantity_in_dying = trx_quantity_in_dying + CASE 
            WHEN NEW.to_section = 'dyeing' OR NEW.to_section = 'coil_dyeing' THEN NEW.trx_quantity 
            ELSE 0 
        END - CASE 
            WHEN OLD.to_section = 'dyeing' OR OLD.to_section = 'coil_dyeing' THEN OLD.trx_quantity 
            ELSE 0 
        END
        - CASE 
            WHEN NEW.to_section = 'stock' THEN NEW.trx_quantity 
            ELSE 0 
        END + CASE 
            WHEN OLD.to_section = 'stock' THEN OLD.trx_quantity 
            ELSE 0 
        END,
        -- Tape to Coil Trx 
        trx_quantity_in_coil = trx_quantity_in_coil + CASE 
            WHEN NEW.to_section = 'coil' THEN NEW.trx_quantity 
            ELSE 0 
        END - CASE 
            WHEN OLD.to_section = 'coil' THEN OLD.trx_quantity 
            ELSE 0 
        END,
        -- Dyed Tape or Coil Stock
        stock_quantity = stock_quantity + CASE 
            WHEN NEW.to_section = 'stock' THEN NEW.trx_quantity 
            ELSE 0 
        END - CASE 
            WHEN OLD.to_section = 'stock' THEN OLD.trx_quantity 
            ELSE 0 
        END
    WHERE uuid = NEW.tape_coil_uuid;
    RETURN NEW;
END;
$$;
 8   DROP FUNCTION zipper.tape_coil_after_tape_trx_update();
       zipper          postgres    false    15            ^           1255    131113 A   tape_coil_and_order_description_after_dyed_tape_transaction_del()    FUNCTION       CREATE FUNCTION zipper.tape_coil_and_order_description_after_dyed_tape_transaction_del() RETURNS trigger
    LANGUAGE plpgsql
    AS $$

BEGIN
    -- Update zipper.tape_coil
    UPDATE zipper.tape_coil
    SET
        stock_quantity = stock_quantity + OLD.trx_quantity
    WHERE uuid = OLD.tape_coil_uuid;
    -- Update zipper.order_description
    UPDATE zipper.order_description
    SET
        tape_transferred = tape_transferred - OLD.trx_quantity
    WHERE uuid = OLD.order_description_uuid;

    RETURN OLD;
END;

$$;
 X   DROP FUNCTION zipper.tape_coil_and_order_description_after_dyed_tape_transaction_del();
       zipper          postgres    false    15            �           1255    131111 A   tape_coil_and_order_description_after_dyed_tape_transaction_ins()    FUNCTION       CREATE FUNCTION zipper.tape_coil_and_order_description_after_dyed_tape_transaction_ins() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    -- Update zipper.tape_coil
    UPDATE zipper.tape_coil
    SET
        stock_quantity = stock_quantity - NEW.trx_quantity
    WHERE uuid = NEW.tape_coil_uuid;
    -- Update zipper.order_description
    UPDATE zipper.order_description
    SET
        tape_transferred = tape_transferred + NEW.trx_quantity
    WHERE uuid = NEW.order_description_uuid;

    RETURN NEW;
END;

$$;
 X   DROP FUNCTION zipper.tape_coil_and_order_description_after_dyed_tape_transaction_ins();
       zipper          postgres    false    15            P           1255    131112 A   tape_coil_and_order_description_after_dyed_tape_transaction_upd()    FUNCTION     2  CREATE FUNCTION zipper.tape_coil_and_order_description_after_dyed_tape_transaction_upd() RETURNS trigger
    LANGUAGE plpgsql
    AS $$

BEGIN
    -- Update zipper.tape_coil
    UPDATE zipper.tape_coil
    SET
        stock_quantity = stock_quantity - NEW.trx_quantity + OLD.trx_quantity
    WHERE uuid = NEW.tape_coil_uuid;
    -- Update zipper.order_description
    UPDATE zipper.order_description
    SET
        tape_transferred = tape_transferred + NEW.trx_quantity - OLD.trx_quantity
    WHERE uuid = NEW.order_description_uuid;

    RETURN NEW;
END;

$$;
 X   DROP FUNCTION zipper.tape_coil_and_order_description_after_dyed_tape_transaction_upd();
       zipper          postgres    false    15            �            1259    18014    bank    TABLE     /  CREATE TABLE commercial.bank (
    uuid text NOT NULL,
    name text NOT NULL,
    swift_code text NOT NULL,
    address text,
    policy text,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone,
    remarks text,
    created_by text,
    routing_no text
);
    DROP TABLE commercial.bank;
    
   commercial         heap    postgres    false    6            �            1259    18019    lc_sequence    SEQUENCE     x   CREATE SEQUENCE commercial.lc_sequence
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 &   DROP SEQUENCE commercial.lc_sequence;
    
   commercial          postgres    false    6            �            1259    18020    lc    TABLE     }  CREATE TABLE commercial.lc (
    uuid text NOT NULL,
    party_uuid text,
    lc_number text NOT NULL,
    lc_date timestamp without time zone NOT NULL,
    payment_value numeric(20,4) DEFAULT 0,
    payment_date timestamp without time zone,
    ldbc_fdbc text,
    acceptance_date timestamp without time zone,
    maturity_date timestamp without time zone,
    commercial_executive text NOT NULL,
    party_bank text NOT NULL,
    production_complete integer DEFAULT 0,
    lc_cancel integer DEFAULT 0,
    handover_date timestamp without time zone,
    shipment_date timestamp without time zone,
    expiry_date timestamp without time zone,
    ud_no text,
    ud_received text,
    at_sight text NOT NULL,
    amd_date timestamp without time zone,
    amd_count integer DEFAULT 0,
    problematical integer DEFAULT 0,
    epz integer DEFAULT 0,
    created_by text,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone,
    remarks text,
    id integer DEFAULT nextval('commercial.lc_sequence'::regclass) NOT NULL,
    document_receive_date timestamp without time zone,
    is_rtgs integer DEFAULT 0
);
    DROP TABLE commercial.lc;
    
   commercial         heap    postgres    false    226    6            �            1259    18032    pi_sequence    SEQUENCE     x   CREATE SEQUENCE commercial.pi_sequence
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 &   DROP SEQUENCE commercial.pi_sequence;
    
   commercial          postgres    false    6            4           1259    81989    pi_cash    TABLE     �  CREATE TABLE commercial.pi_cash (
    uuid text NOT NULL,
    id integer DEFAULT nextval('commercial.pi_sequence'::regclass) NOT NULL,
    lc_uuid text,
    order_info_uuids text NOT NULL,
    marketing_uuid text,
    party_uuid text,
    merchandiser_uuid text,
    factory_uuid text,
    bank_uuid text,
    validity integer DEFAULT 0,
    payment integer DEFAULT 0,
    is_pi integer DEFAULT 0,
    conversion_rate numeric(20,4) DEFAULT 0,
    receive_amount numeric(20,4) DEFAULT 0,
    created_by text,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone,
    remarks text,
    weight numeric(20,4) DEFAULT 0 NOT NULL,
    thread_order_info_uuids text
);
    DROP TABLE commercial.pi_cash;
    
   commercial         heap    postgres    false    228    6            5           1259    82002    pi_cash_entry    TABLE     .  CREATE TABLE commercial.pi_cash_entry (
    uuid text NOT NULL,
    pi_cash_uuid text,
    sfg_uuid text,
    pi_cash_quantity numeric(20,4) NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone,
    remarks text,
    thread_order_entry_uuid text
);
 %   DROP TABLE commercial.pi_cash_entry;
    
   commercial         heap    postgres    false    6            8           1259    122885    challan_sequence    SEQUENCE     {   CREATE SEQUENCE delivery.challan_sequence
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 )   DROP SEQUENCE delivery.challan_sequence;
       delivery          postgres    false    7            �            1259    18044    challan    TABLE     �  CREATE TABLE delivery.challan (
    uuid text NOT NULL,
    carton_quantity integer NOT NULL,
    assign_to text,
    receive_status integer DEFAULT 0,
    created_by text,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone,
    remarks text,
    id integer DEFAULT nextval('delivery.challan_sequence'::regclass),
    gate_pass integer DEFAULT 0,
    order_info_uuid text
);
    DROP TABLE delivery.challan;
       delivery         heap    postgres    false    312    7            �            1259    18050    challan_entry    TABLE     �   CREATE TABLE delivery.challan_entry (
    uuid text NOT NULL,
    challan_uuid text,
    packing_list_uuid text,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone,
    remarks text
);
 #   DROP TABLE delivery.challan_entry;
       delivery         heap    postgres    false    7            6           1259    114693    packing_list_sequence    SEQUENCE     �   CREATE SEQUENCE delivery.packing_list_sequence
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 .   DROP SEQUENCE delivery.packing_list_sequence;
       delivery          postgres    false    7            �            1259    18055    packing_list    TABLE     �  CREATE TABLE delivery.packing_list (
    uuid text NOT NULL,
    carton_size text NOT NULL,
    carton_weight text NOT NULL,
    created_by text,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone,
    remarks text,
    order_info_uuid text,
    id integer DEFAULT nextval('delivery.packing_list_sequence'::regclass),
    challan_uuid text
);
 "   DROP TABLE delivery.packing_list;
       delivery         heap    postgres    false    310    7            �            1259    18060    packing_list_entry    TABLE     Y  CREATE TABLE delivery.packing_list_entry (
    uuid text NOT NULL,
    packing_list_uuid text,
    sfg_uuid text,
    quantity numeric(20,4) NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone,
    remarks text,
    short_quantity integer DEFAULT 0,
    reject_quantity integer DEFAULT 0
);
 (   DROP TABLE delivery.packing_list_entry;
       delivery         heap    postgres    false    7            �            1259    18086    users    TABLE     )  CREATE TABLE hr.users (
    uuid text NOT NULL,
    name text NOT NULL,
    email text NOT NULL,
    pass text NOT NULL,
    designation_uuid text,
    can_access text,
    ext text,
    phone text,
    created_at text NOT NULL,
    updated_at text,
    status text DEFAULT 0,
    remarks text
);
    DROP TABLE hr.users;
       hr         heap    postgres    false    9            �            1259    18190    buyer    TABLE     �   CREATE TABLE public.buyer (
    uuid text NOT NULL,
    name text NOT NULL,
    short_name text,
    remarks text,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone,
    created_by text
);
    DROP TABLE public.buyer;
       public         heap    postgres    false            �            1259    18195    factory    TABLE       CREATE TABLE public.factory (
    uuid text NOT NULL,
    party_uuid text,
    name text NOT NULL,
    phone text,
    address text,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone,
    created_by text,
    remarks text
);
    DROP TABLE public.factory;
       public         heap    postgres    false                        1259    18200 	   marketing    TABLE       CREATE TABLE public.marketing (
    uuid text NOT NULL,
    name text NOT NULL,
    short_name text,
    user_uuid text,
    remarks text,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone,
    created_by text
);
    DROP TABLE public.marketing;
       public         heap    postgres    false                       1259    18205    merchandiser    TABLE     $  CREATE TABLE public.merchandiser (
    uuid text NOT NULL,
    party_uuid text,
    name text NOT NULL,
    email text,
    phone text,
    address text,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone,
    created_by text,
    remarks text
);
     DROP TABLE public.merchandiser;
       public         heap    postgres    false                       1259    18210    party    TABLE       CREATE TABLE public.party (
    uuid text NOT NULL,
    name text NOT NULL,
    short_name text NOT NULL,
    remarks text,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone,
    created_by text,
    address text
);
    DROP TABLE public.party;
       public         heap    postgres    false                       1259    18215 
   properties    TABLE     -  CREATE TABLE public.properties (
    uuid text NOT NULL,
    item_for text NOT NULL,
    type text NOT NULL,
    name text NOT NULL,
    short_name text NOT NULL,
    created_by text,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone,
    remarks text
);
    DROP TABLE public.properties;
       public         heap    postgres    false                       1259    18274    stock    TABLE     a  CREATE TABLE slider.stock (
    uuid text NOT NULL,
    order_quantity numeric(20,4) DEFAULT 0,
    body_quantity numeric(20,4) DEFAULT 0,
    cap_quantity numeric(20,4) DEFAULT 0,
    puller_quantity numeric(20,4) DEFAULT 0,
    link_quantity numeric(20,4) DEFAULT 0,
    sa_prod numeric(20,4) DEFAULT 0,
    coloring_stock numeric(20,4) DEFAULT 0,
    coloring_prod numeric(20,4) DEFAULT 0,
    trx_to_finishing numeric(20,4) DEFAULT 0,
    u_top_quantity numeric(20,4) DEFAULT 0,
    h_bottom_quantity numeric(20,4) DEFAULT 0,
    box_pin_quantity numeric(20,4) DEFAULT 0,
    two_way_pin_quantity numeric(20,4) DEFAULT 0,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone,
    remarks text,
    quantity_in_sa numeric(20,4) DEFAULT 0,
    order_description_uuid text,
    finishing_stock numeric(20,4) DEFAULT 0
);
    DROP TABLE slider.stock;
       slider         heap    postgres    false    13            #           1259    18403    order_description    TABLE     �  CREATE TABLE zipper.order_description (
    uuid text NOT NULL,
    order_info_uuid text,
    item text,
    zipper_number text,
    end_type text,
    lock_type text,
    puller_type text,
    teeth_color text,
    puller_color text,
    special_requirement text,
    hand text,
    coloring_type text,
    is_slider_provided integer DEFAULT 0,
    slider text,
    slider_starting_section_enum zipper.slider_starting_section_enum,
    top_stopper text,
    bottom_stopper text,
    logo_type text,
    is_logo_body integer DEFAULT 0 NOT NULL,
    is_logo_puller integer DEFAULT 0 NOT NULL,
    description text,
    status integer DEFAULT 0 NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone,
    remarks text,
    slider_body_shape text,
    slider_link text,
    end_user text,
    garment text,
    light_preference text,
    garments_wash text,
    created_by text,
    garments_remarks text,
    tape_received numeric(20,4) DEFAULT 0 NOT NULL,
    tape_transferred numeric(20,4) DEFAULT 0 NOT NULL,
    slider_finishing_stock numeric(20,4) DEFAULT 0 NOT NULL,
    nylon_stopper text,
    tape_coil_uuid text,
    teeth_type text
);
 %   DROP TABLE zipper.order_description;
       zipper         heap    postgres    false    15    1034            $           1259    18418    order_entry    TABLE     l  CREATE TABLE zipper.order_entry (
    uuid text NOT NULL,
    order_description_uuid text,
    style text NOT NULL,
    color text NOT NULL,
    size text NOT NULL,
    quantity numeric(20,4) NOT NULL,
    company_price numeric(20,4) DEFAULT 0 NOT NULL,
    party_price numeric(20,4) DEFAULT 0 NOT NULL,
    status integer DEFAULT 1,
    swatch_status_enum zipper.swatch_status_enum DEFAULT 'pending'::zipper.swatch_status_enum,
    swatch_approval_date timestamp without time zone,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone,
    remarks text,
    bleaching text
);
    DROP TABLE zipper.order_entry;
       zipper         heap    postgres    false    1037    1037    15            %           1259    18427    order_info_sequence    SEQUENCE     |   CREATE SEQUENCE zipper.order_info_sequence
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 *   DROP SEQUENCE zipper.order_info_sequence;
       zipper          postgres    false    15            &           1259    18428 
   order_info    TABLE     �  CREATE TABLE zipper.order_info (
    uuid text NOT NULL,
    id integer DEFAULT nextval('zipper.order_info_sequence'::regclass) NOT NULL,
    reference_order_info_uuid text,
    buyer_uuid text,
    party_uuid text,
    marketing_uuid text,
    merchandiser_uuid text,
    factory_uuid text,
    is_sample integer DEFAULT 0,
    is_bill integer DEFAULT 0,
    is_cash integer DEFAULT 0,
    marketing_priority text,
    factory_priority text,
    status integer DEFAULT 0 NOT NULL,
    created_by text,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone,
    remarks text,
    conversion_rate numeric(20,4) DEFAULT 0 NOT NULL,
    print_in zipper.print_in_enum DEFAULT 'portrait'::zipper.print_in_enum
);
    DROP TABLE zipper.order_info;
       zipper         heap    postgres    false    293    1277    15    1277            )           1259    18452    sfg    TABLE     �  CREATE TABLE zipper.sfg (
    uuid text NOT NULL,
    order_entry_uuid text,
    recipe_uuid text,
    dying_and_iron_prod numeric(20,4) DEFAULT 0,
    teeth_molding_stock numeric(20,4) DEFAULT 0,
    teeth_molding_prod numeric(20,4) DEFAULT 0,
    teeth_coloring_stock numeric(20,4) DEFAULT 0,
    teeth_coloring_prod numeric(20,4) DEFAULT 0,
    finishing_stock numeric(20,4) DEFAULT 0,
    finishing_prod numeric(20,4) DEFAULT 0,
    coloring_prod numeric(20,4) DEFAULT 0,
    warehouse numeric(20,4) DEFAULT 0 NOT NULL,
    delivered numeric(20,4) DEFAULT 0 NOT NULL,
    pi numeric(20,4) DEFAULT 0 NOT NULL,
    remarks text,
    short_quantity integer DEFAULT 0,
    reject_quantity integer DEFAULT 0
);
    DROP TABLE zipper.sfg;
       zipper         heap    postgres    false    15            ,           1259    18483 	   tape_coil    TABLE     �  CREATE TABLE zipper.tape_coil (
    uuid text NOT NULL,
    quantity numeric(20,4) DEFAULT 0 NOT NULL,
    trx_quantity_in_coil numeric(20,4) DEFAULT 0 NOT NULL,
    quantity_in_coil numeric(20,4) DEFAULT 0 NOT NULL,
    remarks text,
    item_uuid text,
    zipper_number_uuid text,
    name text NOT NULL,
    raw_per_kg_meter numeric(20,4) DEFAULT 0 NOT NULL,
    dyed_per_kg_meter numeric(20,4) DEFAULT 0 NOT NULL,
    created_by text,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone,
    is_import text,
    is_reverse text,
    trx_quantity_in_dying numeric(20,4) DEFAULT 0 NOT NULL,
    stock_quantity numeric(20,4) DEFAULT 0 NOT NULL
);
    DROP TABLE zipper.tape_coil;
       zipper         heap    postgres    false    15            >           1259    139382    v_order_details_full    VIEW     S  CREATE VIEW zipper.v_order_details_full AS
 SELECT order_info.uuid AS order_info_uuid,
    concat('Z', to_char(order_info.created_at, 'YY'::text), '-', lpad((order_info.id)::text, 4, '0'::text)) AS order_number,
    order_description.uuid AS order_description_uuid,
    order_description.tape_received,
    order_description.tape_transferred,
    order_description.slider_finishing_stock,
    order_info.marketing_uuid,
    marketing.name AS marketing_name,
    order_info.buyer_uuid,
    buyer.name AS buyer_name,
    order_info.merchandiser_uuid,
    merchandiser.name AS merchandiser_name,
    order_info.factory_uuid,
    factory.name AS factory_name,
    factory.address AS factory_address,
    order_info.party_uuid,
    party.name AS party_name,
    order_info.created_by AS created_by_uuid,
    users.name AS created_by_name,
    order_info.is_cash,
    order_info.is_bill,
    order_info.is_sample,
    order_info.status AS order_status,
    order_info.created_at,
    order_info.updated_at,
    order_info.print_in,
    concat(op_item.short_name, op_nylon_stopper.short_name, '-', op_zipper.short_name, '-', op_end.short_name, '-', op_puller.short_name) AS item_description,
    order_description.item,
    op_item.name AS item_name,
    op_item.short_name AS item_short_name,
    order_description.nylon_stopper,
    op_nylon_stopper.name AS nylon_stopper_name,
    op_nylon_stopper.short_name AS nylon_stopper_short_name,
    order_description.zipper_number,
    op_zipper.name AS zipper_number_name,
    op_zipper.short_name AS zipper_number_short_name,
    order_description.end_type,
    op_end.name AS end_type_name,
    op_end.short_name AS end_type_short_name,
    order_description.puller_type,
    op_puller.name AS puller_type_name,
    op_puller.short_name AS puller_type_short_name,
    order_description.lock_type,
    op_lock.name AS lock_type_name,
    op_lock.short_name AS lock_type_short_name,
    order_description.teeth_color,
    op_teeth_color.name AS teeth_color_name,
    op_teeth_color.short_name AS teeth_color_short_name,
    order_description.puller_color,
    op_puller_color.name AS puller_color_name,
    op_puller_color.short_name AS puller_color_short_name,
    order_description.hand,
    op_hand.name AS hand_name,
    op_hand.short_name AS hand_short_name,
    order_description.coloring_type,
    op_coloring.name AS coloring_type_name,
    op_coloring.short_name AS coloring_type_short_name,
    order_description.is_slider_provided,
    order_description.slider,
    op_slider.name AS slider_name,
    op_slider.short_name AS slider_short_name,
    order_description.slider_starting_section_enum AS slider_starting_section,
    order_description.top_stopper,
    op_top_stopper.name AS top_stopper_name,
    op_top_stopper.short_name AS top_stopper_short_name,
    order_description.bottom_stopper,
    op_bottom_stopper.name AS bottom_stopper_name,
    op_bottom_stopper.short_name AS bottom_stopper_short_name,
    order_description.logo_type,
    op_logo.name AS logo_type_name,
    op_logo.short_name AS logo_type_short_name,
    order_description.is_logo_body,
    order_description.is_logo_puller,
    order_description.special_requirement,
    order_description.description,
    order_description.status AS order_description_status,
    order_description.created_at AS order_description_created_at,
    order_description.updated_at AS order_description_updated_at,
    order_description.remarks,
    order_description.slider_body_shape,
    op_slider_body_shape.name AS slider_body_shape_name,
    op_slider_body_shape.short_name AS slider_body_shape_short_name,
    order_description.end_user,
    op_end_user.name AS end_user_name,
    op_end_user.short_name AS end_user_short_name,
    order_description.garment,
    order_description.light_preference,
    op_light_preference.name AS light_preference_name,
    op_light_preference.short_name AS light_preference_short_name,
    order_description.garments_wash,
    order_description.slider_link,
    op_slider_link.name AS slider_link_name,
    op_slider_link.short_name AS slider_link_short_name,
    order_info.marketing_priority,
    order_info.factory_priority,
    order_description.garments_remarks,
    stock.uuid AS stock_uuid,
    stock.order_quantity AS stock_order_quantity,
    order_description.tape_coil_uuid,
    tc.name AS tape_name,
    order_description.teeth_type,
    op_teeth_type.name AS teeth_type_name,
    op_teeth_type.short_name AS teeth_type_short_name
   FROM ((((((((((((((((((((((((((((zipper.order_info
     LEFT JOIN zipper.order_description ON ((order_description.order_info_uuid = order_info.uuid)))
     LEFT JOIN public.marketing ON ((marketing.uuid = order_info.marketing_uuid)))
     LEFT JOIN public.buyer ON ((buyer.uuid = order_info.buyer_uuid)))
     LEFT JOIN public.merchandiser ON ((merchandiser.uuid = order_info.merchandiser_uuid)))
     LEFT JOIN public.factory ON ((factory.uuid = order_info.factory_uuid)))
     LEFT JOIN hr.users users ON ((users.uuid = order_info.created_by)))
     LEFT JOIN public.party ON ((party.uuid = order_info.party_uuid)))
     LEFT JOIN public.properties op_item ON ((op_item.uuid = order_description.item)))
     LEFT JOIN public.properties op_nylon_stopper ON ((op_nylon_stopper.uuid = order_description.nylon_stopper)))
     LEFT JOIN public.properties op_zipper ON ((op_zipper.uuid = order_description.zipper_number)))
     LEFT JOIN public.properties op_end ON ((op_end.uuid = order_description.end_type)))
     LEFT JOIN public.properties op_puller ON ((op_puller.uuid = order_description.puller_type)))
     LEFT JOIN public.properties op_lock ON ((op_lock.uuid = order_description.lock_type)))
     LEFT JOIN public.properties op_teeth_color ON ((op_teeth_color.uuid = order_description.teeth_color)))
     LEFT JOIN public.properties op_puller_color ON ((op_puller_color.uuid = order_description.puller_color)))
     LEFT JOIN public.properties op_hand ON ((op_hand.uuid = order_description.hand)))
     LEFT JOIN public.properties op_coloring ON ((op_coloring.uuid = order_description.coloring_type)))
     LEFT JOIN public.properties op_slider ON ((op_slider.uuid = order_description.slider)))
     LEFT JOIN public.properties op_top_stopper ON ((op_top_stopper.uuid = order_description.top_stopper)))
     LEFT JOIN public.properties op_bottom_stopper ON ((op_bottom_stopper.uuid = order_description.bottom_stopper)))
     LEFT JOIN public.properties op_logo ON ((op_logo.uuid = order_description.logo_type)))
     LEFT JOIN public.properties op_slider_body_shape ON ((op_slider_body_shape.uuid = order_description.slider_body_shape)))
     LEFT JOIN public.properties op_slider_link ON ((op_slider_link.uuid = order_description.slider_link)))
     LEFT JOIN public.properties op_end_user ON ((op_end_user.uuid = order_description.end_user)))
     LEFT JOIN public.properties op_light_preference ON ((op_light_preference.uuid = order_description.light_preference)))
     LEFT JOIN slider.stock ON ((stock.order_description_uuid = order_description.uuid)))
     LEFT JOIN zipper.tape_coil tc ON ((tc.uuid = order_description.tape_coil_uuid)))
     LEFT JOIN public.properties op_teeth_type ON ((op_teeth_type.uuid = order_description.teeth_type)));
 '   DROP VIEW zipper.v_order_details_full;
       zipper          postgres    false    256    291    291    238    294    294    254    254    255    291    291    291    255    255    256    291    291    291    257    257    258    258    291    291    291    259    259    259    270    291    291    291    270    270    291    294    294    294    300    294    294    294    294    294    294    300    294    294    294    294    294    294    291    291    291    291    291    291    291    291    291    291    291    291    291    291    291    291    291    291    291    291    291    291    238    291    1034    15    1277            ?           1259    139387    v_packing_list    VIEW     �  CREATE VIEW delivery.v_packing_list AS
 SELECT pl.id AS packing_list_id,
    pl.uuid AS packing_list_uuid,
    concat('PL', to_char(pl.created_at, 'YY'::text), '-', lpad((pl.id)::text, 4, '0'::text)) AS packing_number,
    pl.carton_size,
    pl.carton_weight,
    pl.order_info_uuid,
    pl.challan_uuid,
    pl.created_by AS created_by_uuid,
    users.name AS created_by_name,
    pl.created_at,
    pl.updated_at,
    pl.remarks,
    ple.uuid AS packing_list_entry_uuid,
    ple.sfg_uuid,
    ple.quantity,
    ple.short_quantity,
    ple.reject_quantity,
    ple.created_at AS entry_created_at,
    ple.updated_at AS entry_updated_at,
    ple.remarks AS entry_remarks,
    oe.uuid AS order_entry_uuid,
    oe.style,
    oe.color,
    oe.size,
    concat(oe.style, ' / ', oe.color, ' / ', oe.size) AS style_color_size,
    oe.quantity AS order_quantity,
    vodf.order_description_uuid,
    vodf.order_number,
    vodf.item_description,
    sfg.warehouse,
    sfg.delivered,
    (oe.quantity - sfg.warehouse) AS balance_quantity
   FROM (((((delivery.packing_list pl
     LEFT JOIN delivery.packing_list_entry ple ON ((ple.packing_list_uuid = pl.uuid)))
     LEFT JOIN hr.users ON ((users.uuid = pl.created_by)))
     LEFT JOIN zipper.sfg ON ((sfg.uuid = ple.sfg_uuid)))
     LEFT JOIN zipper.order_entry oe ON ((oe.uuid = sfg.order_entry_uuid)))
     LEFT JOIN zipper.v_order_details_full vodf ON ((vodf.order_description_uuid = oe.order_description_uuid)));
 #   DROP VIEW delivery.v_packing_list;
       delivery          postgres    false    231    231    231    231    231    231    232    232    297    232    232    232    232    297    297    318    232    232    232    238    231    231    231    231    238    292    292    292    318    318    292    292    292    297    7            �            1259    18065    migrations_details    TABLE     t   CREATE TABLE drizzle.migrations_details (
    id integer NOT NULL,
    hash text NOT NULL,
    created_at bigint
);
 '   DROP TABLE drizzle.migrations_details;
       drizzle         heap    postgres    false    8            �            1259    18070    migrations_details_id_seq    SEQUENCE     �   CREATE SEQUENCE drizzle.migrations_details_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 1   DROP SEQUENCE drizzle.migrations_details_id_seq;
       drizzle          postgres    false    8    233            H           0    0    migrations_details_id_seq    SEQUENCE OWNED BY     Y   ALTER SEQUENCE drizzle.migrations_details_id_seq OWNED BY drizzle.migrations_details.id;
          drizzle          postgres    false    234            �            1259    18071 
   department    TABLE     �   CREATE TABLE hr.department (
    uuid text NOT NULL,
    department text NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone,
    remarks text
);
    DROP TABLE hr.department;
       hr         heap    postgres    false    9            �            1259    18076    designation    TABLE     �   CREATE TABLE hr.designation (
    uuid text NOT NULL,
    department_uuid text,
    designation text NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone,
    remarks text
);
    DROP TABLE hr.designation;
       hr         heap    postgres    false    9            �            1259    18081    policy_and_notice    TABLE       CREATE TABLE hr.policy_and_notice (
    uuid text NOT NULL,
    type text NOT NULL,
    title text NOT NULL,
    sub_title text NOT NULL,
    url text NOT NULL,
    created_at text NOT NULL,
    updated_at text,
    status integer NOT NULL,
    remarks text,
    created_by text
);
 !   DROP TABLE hr.policy_and_notice;
       hr         heap    postgres    false    9            �            1259    18092    info    TABLE     L  CREATE TABLE lab_dip.info (
    uuid text NOT NULL,
    id integer NOT NULL,
    name text NOT NULL,
    order_info_uuid text,
    created_by text,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone,
    remarks text,
    lab_status integer DEFAULT 0,
    thread_order_info_uuid text
);
    DROP TABLE lab_dip.info;
       lab_dip         heap    postgres    false    10            �            1259    18098    info_id_seq    SEQUENCE     �   CREATE SEQUENCE lab_dip.info_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 #   DROP SEQUENCE lab_dip.info_id_seq;
       lab_dip          postgres    false    10    239            I           0    0    info_id_seq    SEQUENCE OWNED BY     =   ALTER SEQUENCE lab_dip.info_id_seq OWNED BY lab_dip.info.id;
          lab_dip          postgres    false    240            �            1259    18099    recipe    TABLE     t  CREATE TABLE lab_dip.recipe (
    uuid text NOT NULL,
    id integer NOT NULL,
    lab_dip_info_uuid text,
    name text NOT NULL,
    approved integer DEFAULT 0,
    created_by text,
    status integer DEFAULT 0,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone,
    remarks text,
    sub_streat text,
    bleaching text
);
    DROP TABLE lab_dip.recipe;
       lab_dip         heap    postgres    false    10            �            1259    18106    recipe_entry    TABLE       CREATE TABLE lab_dip.recipe_entry (
    uuid text NOT NULL,
    recipe_uuid text,
    color text NOT NULL,
    quantity numeric(20,4) NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone,
    remarks text,
    material_uuid text
);
 !   DROP TABLE lab_dip.recipe_entry;
       lab_dip         heap    postgres    false    10            �            1259    18111    recipe_id_seq    SEQUENCE     �   CREATE SEQUENCE lab_dip.recipe_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 %   DROP SEQUENCE lab_dip.recipe_id_seq;
       lab_dip          postgres    false    241    10            J           0    0    recipe_id_seq    SEQUENCE OWNED BY     A   ALTER SEQUENCE lab_dip.recipe_id_seq OWNED BY lab_dip.recipe.id;
          lab_dip          postgres    false    243            �            1259    18112    shade_recipe_sequence    SEQUENCE        CREATE SEQUENCE lab_dip.shade_recipe_sequence
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 -   DROP SEQUENCE lab_dip.shade_recipe_sequence;
       lab_dip          postgres    false    10            �            1259    18113    shade_recipe    TABLE     }  CREATE TABLE lab_dip.shade_recipe (
    uuid text NOT NULL,
    id integer DEFAULT nextval('lab_dip.shade_recipe_sequence'::regclass) NOT NULL,
    name text NOT NULL,
    sub_streat text,
    lab_status integer DEFAULT 0,
    created_by text,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone,
    remarks text,
    bleaching text
);
 !   DROP TABLE lab_dip.shade_recipe;
       lab_dip         heap    postgres    false    244    10            �            1259    18120    shade_recipe_entry    TABLE       CREATE TABLE lab_dip.shade_recipe_entry (
    uuid text NOT NULL,
    shade_recipe_uuid text,
    material_uuid text,
    quantity numeric(20,4) NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone,
    remarks text
);
 '   DROP TABLE lab_dip.shade_recipe_entry;
       lab_dip         heap    postgres    false    10            �            1259    18125    info    TABLE     u  CREATE TABLE material.info (
    uuid text NOT NULL,
    section_uuid text,
    type_uuid text,
    name text NOT NULL,
    short_name text,
    unit text NOT NULL,
    threshold numeric(20,4) DEFAULT 0 NOT NULL,
    description text,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone,
    remarks text,
    created_by text
);
    DROP TABLE material.info;
       material         heap    postgres    false    11            �            1259    18131    section    TABLE     �   CREATE TABLE material.section (
    uuid text NOT NULL,
    name text NOT NULL,
    short_name text,
    remarks text,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone,
    created_by text
);
    DROP TABLE material.section;
       material         heap    postgres    false    11            �            1259    18136    stock    TABLE     �  CREATE TABLE material.stock (
    uuid text NOT NULL,
    material_uuid text,
    stock numeric(20,4) DEFAULT 0 NOT NULL,
    tape_making numeric(20,4) DEFAULT 0 NOT NULL,
    coil_forming numeric(20,4) DEFAULT 0 NOT NULL,
    dying_and_iron numeric(20,4) DEFAULT 0 NOT NULL,
    m_gapping numeric(20,4) DEFAULT 0 NOT NULL,
    v_gapping numeric(20,4) DEFAULT 0 NOT NULL,
    v_teeth_molding numeric(20,4) DEFAULT 0 NOT NULL,
    m_teeth_molding numeric(20,4) DEFAULT 0 NOT NULL,
    teeth_assembling_and_polishing numeric(20,4) DEFAULT 0 NOT NULL,
    m_teeth_cleaning numeric(20,4) DEFAULT 0 NOT NULL,
    v_teeth_cleaning numeric(20,4) DEFAULT 0 NOT NULL,
    plating_and_iron numeric(20,4) DEFAULT 0 NOT NULL,
    m_sealing numeric(20,4) DEFAULT 0 NOT NULL,
    v_sealing numeric(20,4) DEFAULT 0 NOT NULL,
    n_t_cutting numeric(20,4) DEFAULT 0 NOT NULL,
    v_t_cutting numeric(20,4) DEFAULT 0 NOT NULL,
    m_stopper numeric(20,4) DEFAULT 0 NOT NULL,
    v_stopper numeric(20,4) DEFAULT 0 NOT NULL,
    n_stopper numeric(20,4) DEFAULT 0 NOT NULL,
    cutting numeric(20,4) DEFAULT 0 NOT NULL,
    die_casting numeric(20,4) DEFAULT 0 NOT NULL,
    slider_assembly numeric(20,4) DEFAULT 0 NOT NULL,
    coloring numeric(20,4) DEFAULT 0 NOT NULL,
    remarks text,
    lab_dip numeric(20,4) DEFAULT 0,
    m_qc_and_packing numeric(20,4) DEFAULT 0 NOT NULL,
    v_qc_and_packing numeric(20,4) DEFAULT 0 NOT NULL,
    n_qc_and_packing numeric(20,4) DEFAULT 0 NOT NULL,
    s_qc_and_packing numeric(20,4) DEFAULT 0 NOT NULL
);
    DROP TABLE material.stock;
       material         heap    postgres    false    11            �            1259    18169    stock_to_sfg    TABLE     =  CREATE TABLE material.stock_to_sfg (
    uuid text NOT NULL,
    material_uuid text,
    order_entry_uuid text,
    trx_to text NOT NULL,
    trx_quantity numeric(20,4) NOT NULL,
    created_by text,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone,
    remarks text
);
 "   DROP TABLE material.stock_to_sfg;
       material         heap    postgres    false    11            �            1259    18174    trx    TABLE       CREATE TABLE material.trx (
    uuid text NOT NULL,
    material_uuid text,
    trx_to text NOT NULL,
    trx_quantity numeric(20,4) NOT NULL,
    created_by text,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone,
    remarks text
);
    DROP TABLE material.trx;
       material         heap    postgres    false    11            �            1259    18179    type    TABLE     �   CREATE TABLE material.type (
    uuid text NOT NULL,
    name text NOT NULL,
    short_name text,
    remarks text,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone,
    created_by text
);
    DROP TABLE material.type;
       material         heap    postgres    false    11            �            1259    18184    used    TABLE     J  CREATE TABLE material.used (
    uuid text NOT NULL,
    material_uuid text,
    section text NOT NULL,
    used_quantity numeric(20,4) NOT NULL,
    wastage numeric(20,4) DEFAULT 0 NOT NULL,
    created_by text,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone,
    remarks text
);
    DROP TABLE material.used;
       material         heap    postgres    false    11            1           1259    73775    machine    TABLE     1  CREATE TABLE public.machine (
    uuid text NOT NULL,
    name text NOT NULL,
    is_vislon integer DEFAULT 0,
    is_metal integer DEFAULT 0,
    is_nylon integer DEFAULT 0,
    is_sewing_thread integer DEFAULT 0,
    is_bulk integer DEFAULT 0,
    is_sample integer DEFAULT 0,
    min_capacity numeric(20,4) NOT NULL,
    max_capacity numeric(20,4) NOT NULL,
    water_capacity numeric(20,4) DEFAULT 0 NOT NULL,
    created_by text NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone,
    remarks text
);
    DROP TABLE public.machine;
       public         heap    postgres    false                       1259    18220    section    TABLE     w   CREATE TABLE public.section (
    uuid text NOT NULL,
    name text NOT NULL,
    short_name text,
    remarks text
);
    DROP TABLE public.section;
       public         heap    postgres    false                       1259    18225    purchase_description_sequence    SEQUENCE     �   CREATE SEQUENCE purchase.purchase_description_sequence
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 6   DROP SEQUENCE purchase.purchase_description_sequence;
       purchase          postgres    false    12                       1259    18226    description    TABLE     �  CREATE TABLE purchase.description (
    uuid text NOT NULL,
    vendor_uuid text,
    is_local integer NOT NULL,
    lc_number text,
    created_by text,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone,
    remarks text,
    id integer DEFAULT nextval('purchase.purchase_description_sequence'::regclass) NOT NULL,
    challan_number text
);
 !   DROP TABLE purchase.description;
       purchase         heap    postgres    false    261    12                       1259    18232    entry    TABLE     ;  CREATE TABLE purchase.entry (
    uuid text NOT NULL,
    purchase_description_uuid text,
    material_uuid text,
    quantity numeric(20,4) NOT NULL,
    price numeric(20,4) DEFAULT NULL::numeric,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone,
    remarks text
);
    DROP TABLE purchase.entry;
       purchase         heap    postgres    false    12                       1259    18238    vendor    TABLE     M  CREATE TABLE purchase.vendor (
    uuid text NOT NULL,
    name text NOT NULL,
    contact_name text NOT NULL,
    email text NOT NULL,
    office_address text NOT NULL,
    contact_number text,
    remarks text,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone,
    created_by text
);
    DROP TABLE purchase.vendor;
       purchase         heap    postgres    false    12            2           1259    73799    assembly_stock    TABLE     �  CREATE TABLE slider.assembly_stock (
    uuid text NOT NULL,
    name text NOT NULL,
    die_casting_body_uuid text,
    die_casting_puller_uuid text,
    die_casting_cap_uuid text,
    die_casting_link_uuid text,
    quantity numeric(20,4) DEFAULT 0 NOT NULL,
    created_by text,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone,
    remarks text,
    weight numeric(20,4) DEFAULT 0 NOT NULL
);
 "   DROP TABLE slider.assembly_stock;
       slider         heap    postgres    false    13            	           1259    18243    coloring_transaction    TABLE     R  CREATE TABLE slider.coloring_transaction (
    uuid text NOT NULL,
    stock_uuid text,
    order_info_uuid text,
    trx_quantity numeric(20,4) NOT NULL,
    created_by text,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone,
    remarks text,
    weight numeric(20,4) DEFAULT 0 NOT NULL
);
 (   DROP TABLE slider.coloring_transaction;
       slider         heap    postgres    false    13            
           1259    18248    die_casting    TABLE     T  CREATE TABLE slider.die_casting (
    uuid text NOT NULL,
    name text NOT NULL,
    item text,
    zipper_number text,
    end_type text,
    puller_type text,
    logo_type text,
    slider_body_shape text,
    slider_link text,
    quantity numeric(20,4) DEFAULT 0,
    weight numeric(20,4) DEFAULT 0,
    pcs_per_kg numeric(20,4) DEFAULT 0,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone,
    remarks text,
    quantity_in_sa numeric(20,4) DEFAULT 0,
    is_logo_body integer DEFAULT 0,
    is_logo_puller integer DEFAULT 0,
    type text
);
    DROP TABLE slider.die_casting;
       slider         heap    postgres    false    13                       1259    18259    die_casting_production    TABLE     �  CREATE TABLE slider.die_casting_production (
    uuid text NOT NULL,
    die_casting_uuid text,
    mc_no integer NOT NULL,
    cavity_goods integer NOT NULL,
    cavity_defect integer NOT NULL,
    push integer NOT NULL,
    weight numeric(20,4) NOT NULL,
    order_description_uuid text,
    created_by text,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone,
    remarks text
);
 *   DROP TABLE slider.die_casting_production;
       slider         heap    postgres    false    13            3           1259    81937    die_casting_to_assembly_stock    TABLE     �  CREATE TABLE slider.die_casting_to_assembly_stock (
    uuid text NOT NULL,
    assembly_stock_uuid text,
    production_quantity numeric(20,4) DEFAULT 0 NOT NULL,
    wastage numeric(20,4) DEFAULT 0 NOT NULL,
    created_by text,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone,
    remarks text,
    with_link integer DEFAULT 1,
    weight numeric(20,4) DEFAULT 0 NOT NULL
);
 1   DROP TABLE slider.die_casting_to_assembly_stock;
       slider         heap    postgres    false    13                       1259    18264    die_casting_transaction    TABLE     V  CREATE TABLE slider.die_casting_transaction (
    uuid text NOT NULL,
    die_casting_uuid text,
    stock_uuid text,
    trx_quantity numeric(20,4) NOT NULL,
    created_by text,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone,
    remarks text,
    weight numeric(20,4) DEFAULT 0 NOT NULL
);
 +   DROP TABLE slider.die_casting_transaction;
       slider         heap    postgres    false    13                       1259    18269 
   production    TABLE     �  CREATE TABLE slider.production (
    uuid text NOT NULL,
    stock_uuid text,
    production_quantity numeric(20,4) NOT NULL,
    wastage numeric(20,4) NOT NULL,
    section text,
    created_by text,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone,
    remarks text,
    with_link integer DEFAULT 1,
    weight numeric(20,4) DEFAULT 0 NOT NULL
);
    DROP TABLE slider.production;
       slider         heap    postgres    false    13                       1259    18293    transaction    TABLE     �  CREATE TABLE slider.transaction (
    uuid text NOT NULL,
    stock_uuid text,
    trx_quantity numeric(20,4) NOT NULL,
    created_by text,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone,
    remarks text,
    from_section text NOT NULL,
    to_section text NOT NULL,
    assembly_stock_uuid text,
    weight numeric(20,4) DEFAULT 0 NOT NULL
);
    DROP TABLE slider.transaction;
       slider         heap    postgres    false    13                       1259    18298    trx_against_stock    TABLE     7  CREATE TABLE slider.trx_against_stock (
    uuid text NOT NULL,
    die_casting_uuid text,
    quantity numeric(20,4) NOT NULL,
    created_by text,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone,
    remarks text,
    weight numeric(20,4) DEFAULT 0 NOT NULL
);
 %   DROP TABLE slider.trx_against_stock;
       slider         heap    postgres    false    13                       1259    18303    thread_batch_sequence    SEQUENCE     ~   CREATE SEQUENCE thread.thread_batch_sequence
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 ,   DROP SEQUENCE thread.thread_batch_sequence;
       thread          postgres    false    14                       1259    18304    batch    TABLE     �  CREATE TABLE thread.batch (
    uuid text NOT NULL,
    id integer DEFAULT nextval('thread.thread_batch_sequence'::regclass) NOT NULL,
    dyeing_operator text,
    reason text,
    category text,
    status text,
    pass_by text,
    shift text,
    dyeing_supervisor text,
    coning_operator text,
    coning_supervisor text,
    coning_machines text,
    created_by text,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone,
    remarks text,
    yarn_quantity numeric(20,4) DEFAULT 0 NOT NULL,
    machine_uuid text,
    lab_created_by text,
    lab_created_at timestamp without time zone,
    lab_updated_at timestamp without time zone,
    yarn_issue_created_by text,
    yarn_issue_created_at timestamp without time zone,
    yarn_issue_updated_at timestamp without time zone,
    is_drying_complete text,
    drying_created_at timestamp without time zone,
    drying_updated_at timestamp without time zone,
    dyeing_created_by text,
    dyeing_created_at timestamp without time zone,
    dyeing_updated_at timestamp without time zone,
    coning_created_by text,
    coning_created_at timestamp without time zone,
    coning_updated_at timestamp without time zone,
    slot integer DEFAULT 0
);
    DROP TABLE thread.batch;
       thread         heap    postgres    false    273    14                       1259    18311    batch_entry    TABLE     Z  CREATE TABLE thread.batch_entry (
    uuid text NOT NULL,
    batch_uuid text,
    order_entry_uuid text,
    quantity numeric(20,4) DEFAULT 0 NOT NULL,
    coning_production_quantity numeric(20,4) DEFAULT 0 NOT NULL,
    coning_carton_quantity numeric(20,4) DEFAULT 0 NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone,
    remarks text,
    coning_created_at timestamp without time zone,
    coning_updated_at timestamp without time zone,
    transfer_quantity numeric(20,4) DEFAULT 0 NOT NULL,
    transfer_carton_quantity integer DEFAULT 0
);
    DROP TABLE thread.batch_entry;
       thread         heap    postgres    false    14            :           1259    131188    batch_entry_production    TABLE     M  CREATE TABLE thread.batch_entry_production (
    uuid text NOT NULL,
    batch_entry_uuid text,
    production_quantity numeric(20,4) NOT NULL,
    coning_carton_quantity numeric(20,4) NOT NULL,
    created_by text,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone,
    remarks text
);
 *   DROP TABLE thread.batch_entry_production;
       thread         heap    postgres    false    14            ;           1259    131195    batch_entry_trx    TABLE     /  CREATE TABLE thread.batch_entry_trx (
    uuid text NOT NULL,
    batch_entry_uuid text,
    quantity numeric(20,4) NOT NULL,
    created_by text,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone,
    remarks text,
    carton_quantity integer DEFAULT 0
);
 #   DROP TABLE thread.batch_entry_trx;
       thread         heap    postgres    false    14            <           1259    131202    challan    TABLE     U  CREATE TABLE thread.challan (
    uuid text NOT NULL,
    order_info_uuid text,
    carton_quantity integer NOT NULL,
    created_by text,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone,
    remarks text,
    assign_to text,
    gate_pass integer DEFAULT 0,
    received integer DEFAULT 0
);
    DROP TABLE thread.challan;
       thread         heap    postgres    false    14            =           1259    131209    challan_entry    TABLE     �  CREATE TABLE thread.challan_entry (
    uuid text NOT NULL,
    challan_uuid text,
    order_entry_uuid text,
    quantity numeric(20,4) NOT NULL,
    created_by text,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone,
    remarks text,
    carton_quantity integer NOT NULL,
    short_quantity numeric(20,4) DEFAULT 0 NOT NULL,
    reject_quantity numeric(20,4) DEFAULT 0 NOT NULL
);
 !   DROP TABLE thread.challan_entry;
       thread         heap    postgres    false    14                       1259    18320    count_length    TABLE     �  CREATE TABLE thread.count_length (
    uuid text NOT NULL,
    count text NOT NULL,
    sst text NOT NULL,
    created_by text NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone,
    remarks text,
    min_weight numeric(20,4),
    max_weight numeric(20,4),
    length numeric NOT NULL,
    price numeric(20,4) NOT NULL,
    cone_per_carton integer DEFAULT 0 NOT NULL
);
     DROP TABLE thread.count_length;
       thread         heap    postgres    false    14                       1259    18325    dyes_category    TABLE     B  CREATE TABLE thread.dyes_category (
    uuid text NOT NULL,
    name text NOT NULL,
    upto_percentage numeric(20,4) DEFAULT 0 NOT NULL,
    bleaching text,
    id integer DEFAULT 0,
    created_by text,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone,
    remarks text
);
 !   DROP TABLE thread.dyes_category;
       thread         heap    postgres    false    14                       1259    18338    order_entry    TABLE        CREATE TABLE thread.order_entry (
    uuid text NOT NULL,
    order_info_uuid text,
    lab_reference text,
    color text NOT NULL,
    po text,
    style text,
    count_length_uuid text,
    quantity numeric(20,4) NOT NULL,
    company_price numeric(20,4) DEFAULT 0 NOT NULL,
    party_price numeric(20,4) DEFAULT 0 NOT NULL,
    swatch_approval_date timestamp without time zone,
    production_quantity numeric(20,4) DEFAULT 0 NOT NULL,
    created_by text,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone,
    remarks text,
    bleaching text,
    transfer_quantity numeric(20,4) DEFAULT 0 NOT NULL,
    recipe_uuid text,
    pi numeric(20,4) DEFAULT 0 NOT NULL,
    delivered numeric(20,4) DEFAULT 0 NOT NULL,
    warehouse numeric(20,4) DEFAULT 0 NOT NULL,
    short_quantity numeric(20,4) DEFAULT 0 NOT NULL,
    reject_quantity numeric(20,4) DEFAULT 0 NOT NULL,
    production_quantity_in_kg numeric(20,4) DEFAULT 0 NOT NULL,
    carton_quantity integer DEFAULT 0
);
    DROP TABLE thread.order_entry;
       thread         heap    postgres    false    14                       1259    18347    thread_order_info_sequence    SEQUENCE     �   CREATE SEQUENCE thread.thread_order_info_sequence
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 1   DROP SEQUENCE thread.thread_order_info_sequence;
       thread          postgres    false    14                       1259    18348 
   order_info    TABLE       CREATE TABLE thread.order_info (
    uuid text NOT NULL,
    id integer DEFAULT nextval('thread.thread_order_info_sequence'::regclass) NOT NULL,
    party_uuid text,
    marketing_uuid text,
    factory_uuid text,
    merchandiser_uuid text,
    buyer_uuid text,
    is_sample integer DEFAULT 0,
    is_bill integer DEFAULT 0,
    delivery_date timestamp without time zone,
    created_by text,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone,
    remarks text,
    is_cash integer DEFAULT 0
);
    DROP TABLE thread.order_info;
       thread         heap    postgres    false    279    14                       1259    18356    programs    TABLE     %  CREATE TABLE thread.programs (
    uuid text NOT NULL,
    dyes_category_uuid text,
    material_uuid text,
    quantity numeric(20,4) DEFAULT 0 NOT NULL,
    created_by text,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone,
    remarks text
);
    DROP TABLE thread.programs;
       thread         heap    postgres    false    14                       1259    18362    batch    TABLE     w  CREATE TABLE zipper.batch (
    uuid text NOT NULL,
    id integer NOT NULL,
    created_by text,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone,
    remarks text,
    batch_status zipper.batch_status DEFAULT 'pending'::zipper.batch_status,
    machine_uuid text,
    slot integer DEFAULT 0,
    received integer DEFAULT 0
);
    DROP TABLE zipper.batch;
       zipper         heap    postgres    false    1031    15    1031                       1259    18368    batch_entry    TABLE     n  CREATE TABLE zipper.batch_entry (
    uuid text NOT NULL,
    batch_uuid text,
    quantity numeric(20,4) DEFAULT 0 NOT NULL,
    production_quantity numeric(20,4) DEFAULT 0,
    production_quantity_in_kg numeric(20,4) DEFAULT 0,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone,
    remarks text,
    sfg_uuid text
);
    DROP TABLE zipper.batch_entry;
       zipper         heap    postgres    false    15                       1259    18376    batch_id_seq    SEQUENCE     �   CREATE SEQUENCE zipper.batch_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 #   DROP SEQUENCE zipper.batch_id_seq;
       zipper          postgres    false    282    15            K           0    0    batch_id_seq    SEQUENCE OWNED BY     =   ALTER SEQUENCE zipper.batch_id_seq OWNED BY zipper.batch.id;
          zipper          postgres    false    284                       1259    18377    batch_production    TABLE     J  CREATE TABLE zipper.batch_production (
    uuid text NOT NULL,
    batch_entry_uuid text,
    production_quantity numeric(20,4) NOT NULL,
    production_quantity_in_kg numeric(20,4) NOT NULL,
    created_by text,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone,
    remarks text
);
 $   DROP TABLE zipper.batch_production;
       zipper         heap    postgres    false    15                       1259    18382    dyed_tape_transaction    TABLE     )  CREATE TABLE zipper.dyed_tape_transaction (
    uuid text NOT NULL,
    order_description_uuid text,
    colors text,
    trx_quantity numeric(20,4) NOT NULL,
    created_by text,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone,
    remarks text
);
 )   DROP TABLE zipper.dyed_tape_transaction;
       zipper         heap    postgres    false    15            9           1259    131078     dyed_tape_transaction_from_stock    TABLE     F  CREATE TABLE zipper.dyed_tape_transaction_from_stock (
    uuid text NOT NULL,
    order_description_uuid text,
    trx_quantity numeric(20,4) DEFAULT 0 NOT NULL,
    tape_coil_uuid text,
    created_by text,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone,
    remarks text
);
 4   DROP TABLE zipper.dyed_tape_transaction_from_stock;
       zipper         heap    postgres    false    15                       1259    18387    dying_batch    TABLE     �   CREATE TABLE zipper.dying_batch (
    uuid text NOT NULL,
    id integer NOT NULL,
    mc_no integer NOT NULL,
    created_by text,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone,
    remarks text
);
    DROP TABLE zipper.dying_batch;
       zipper         heap    postgres    false    15                        1259    18392    dying_batch_entry    TABLE     v  CREATE TABLE zipper.dying_batch_entry (
    uuid text NOT NULL,
    dying_batch_uuid text,
    batch_entry_uuid text,
    quantity numeric(20,4) NOT NULL,
    production_quantity numeric(20,4) NOT NULL,
    production_quantity_in_kg numeric(20,4) NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone,
    remarks text
);
 %   DROP TABLE zipper.dying_batch_entry;
       zipper         heap    postgres    false    15            !           1259    18397    dying_batch_id_seq    SEQUENCE     �   CREATE SEQUENCE zipper.dying_batch_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 )   DROP SEQUENCE zipper.dying_batch_id_seq;
       zipper          postgres    false    15    287            L           0    0    dying_batch_id_seq    SEQUENCE OWNED BY     I   ALTER SEQUENCE zipper.dying_batch_id_seq OWNED BY zipper.dying_batch.id;
          zipper          postgres    false    289            "           1259    18398 &   material_trx_against_order_description    TABLE     [  CREATE TABLE zipper.material_trx_against_order_description (
    uuid text NOT NULL,
    order_description_uuid text,
    material_uuid text,
    trx_to text NOT NULL,
    trx_quantity numeric(20,4) NOT NULL,
    created_by text,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone,
    remarks text
);
 :   DROP TABLE zipper.material_trx_against_order_description;
       zipper         heap    postgres    false    15            '           1259    18438    planning    TABLE     �   CREATE TABLE zipper.planning (
    week text NOT NULL,
    created_by text,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone,
    remarks text
);
    DROP TABLE zipper.planning;
       zipper         heap    postgres    false    15            (           1259    18443    planning_entry    TABLE     �  CREATE TABLE zipper.planning_entry (
    uuid text NOT NULL,
    sfg_uuid text,
    sno_quantity numeric(20,4) DEFAULT 0,
    factory_quantity numeric(20,4) DEFAULT 0,
    production_quantity numeric(20,4) DEFAULT 0,
    batch_production_quantity numeric(20,4) DEFAULT 0,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone,
    planning_week text,
    sno_remarks text,
    factory_remarks text
);
 "   DROP TABLE zipper.planning_entry;
       zipper         heap    postgres    false    15            *           1259    18468    sfg_production    TABLE     �  CREATE TABLE zipper.sfg_production (
    uuid text NOT NULL,
    sfg_uuid text,
    section text NOT NULL,
    production_quantity_in_kg numeric(20,4) DEFAULT 0,
    production_quantity numeric(20,4) DEFAULT 0,
    wastage numeric(20,4) DEFAULT 0,
    created_by text,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone,
    remarks text
);
 "   DROP TABLE zipper.sfg_production;
       zipper         heap    postgres    false    15            +           1259    18476    sfg_transaction    TABLE     �  CREATE TABLE zipper.sfg_transaction (
    uuid text NOT NULL,
    trx_from text NOT NULL,
    trx_to text NOT NULL,
    trx_quantity numeric(20,4) DEFAULT 0,
    slider_item_uuid text,
    created_by text,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone,
    remarks text,
    sfg_uuid text,
    trx_quantity_in_kg numeric(20,4) DEFAULT 0 NOT NULL
);
 #   DROP TABLE zipper.sfg_transaction;
       zipper         heap    postgres    false    15            -           1259    18488    tape_coil_production    TABLE     _  CREATE TABLE zipper.tape_coil_production (
    uuid text NOT NULL,
    section text NOT NULL,
    tape_coil_uuid text,
    production_quantity numeric(20,4) NOT NULL,
    wastage numeric(20,4) DEFAULT 0 NOT NULL,
    created_by text,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone,
    remarks text
);
 (   DROP TABLE zipper.tape_coil_production;
       zipper         heap    postgres    false    15            0           1259    65568    tape_coil_required    TABLE     t  CREATE TABLE zipper.tape_coil_required (
    uuid text NOT NULL,
    end_type_uuid text,
    item_uuid text,
    nylon_stopper_uuid text,
    zipper_number_uuid text,
    top numeric(20,4) NOT NULL,
    bottom numeric(20,4) NOT NULL,
    created_by text,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone,
    remarks text
);
 &   DROP TABLE zipper.tape_coil_required;
       zipper         heap    postgres    false    15            .           1259    18494    tape_coil_to_dyeing    TABLE     /  CREATE TABLE zipper.tape_coil_to_dyeing (
    uuid text NOT NULL,
    tape_coil_uuid text,
    order_description_uuid text,
    trx_quantity numeric(20,4) NOT NULL,
    created_by text,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone,
    remarks text
);
 '   DROP TABLE zipper.tape_coil_to_dyeing;
       zipper         heap    postgres    false    15            /           1259    18499    tape_trx    TABLE       CREATE TABLE zipper.tape_trx (
    uuid text NOT NULL,
    tape_coil_uuid text,
    trx_quantity numeric(20,4) NOT NULL,
    created_by text,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone,
    remarks text,
    to_section text
);
    DROP TABLE zipper.tape_trx;
       zipper         heap    postgres    false    15            7           1259    114701    v_order_details    VIEW     Y	  CREATE VIEW zipper.v_order_details AS
 SELECT order_info.uuid AS order_info_uuid,
    order_info.reference_order_info_uuid,
    concat('Z', to_char(order_info.created_at, 'YY'::text), '-', lpad((order_info.id)::text, 4, '0'::text)) AS order_number,
    concat(op_item.short_name, op_nylon_stopper.short_name, '-', op_zipper.short_name, '-', op_end.short_name, '-', op_puller.short_name) AS item_description,
    op_item.name AS item_name,
    op_nylon_stopper.name AS nylon_stopper_name,
    op_zipper.name AS zipper_number_name,
    op_end.name AS end_type_name,
    op_puller.name AS puller_type_name,
    order_description.uuid AS order_description_uuid,
    order_info.buyer_uuid,
    buyer.name AS buyer_name,
    order_info.party_uuid,
    party.name AS party_name,
    order_info.marketing_uuid,
    marketing.name AS marketing_name,
    order_info.merchandiser_uuid,
    merchandiser.name AS merchandiser_name,
    order_info.factory_uuid,
    factory.name AS factory_name,
    order_info.is_sample,
    order_info.is_bill,
    order_info.is_cash,
    order_info.marketing_priority,
    order_info.factory_priority,
    order_info.status,
    order_info.created_by AS created_by_uuid,
    users.name AS created_by_name,
    order_info.created_at,
    order_info.updated_at,
    order_info.remarks
   FROM ((((((((((((zipper.order_info
     LEFT JOIN zipper.order_description ON ((order_description.order_info_uuid = order_info.uuid)))
     LEFT JOIN public.marketing ON ((marketing.uuid = order_info.marketing_uuid)))
     LEFT JOIN public.buyer ON ((buyer.uuid = order_info.buyer_uuid)))
     LEFT JOIN public.merchandiser ON ((merchandiser.uuid = order_info.merchandiser_uuid)))
     LEFT JOIN public.factory ON ((factory.uuid = order_info.factory_uuid)))
     LEFT JOIN hr.users ON ((users.uuid = order_info.created_by)))
     LEFT JOIN public.party ON ((party.uuid = order_info.party_uuid)))
     LEFT JOIN public.properties op_item ON ((op_item.uuid = order_description.item)))
     LEFT JOIN public.properties op_zipper ON ((op_zipper.uuid = order_description.zipper_number)))
     LEFT JOIN public.properties op_end ON ((op_end.uuid = order_description.end_type)))
     LEFT JOIN public.properties op_puller ON ((op_puller.uuid = order_description.puller_type)))
     LEFT JOIN public.properties op_nylon_stopper ON ((op_nylon_stopper.uuid = order_description.nylon_stopper)));
 "   DROP VIEW zipper.v_order_details;
       zipper          postgres    false    256    294    294    294    294    294    294    294    294    294    294    294    294    294    294    294    294    294    294    291    291    291    291    291    291    291    259    259    259    258    258    257    257    256    255    255    254    254    238    238    15            �           2604    18514    migrations_details id    DEFAULT     �   ALTER TABLE ONLY drizzle.migrations_details ALTER COLUMN id SET DEFAULT nextval('drizzle.migrations_details_id_seq'::regclass);
 E   ALTER TABLE drizzle.migrations_details ALTER COLUMN id DROP DEFAULT;
       drizzle          postgres    false    234    233            �           2604    18515    info id    DEFAULT     d   ALTER TABLE ONLY lab_dip.info ALTER COLUMN id SET DEFAULT nextval('lab_dip.info_id_seq'::regclass);
 7   ALTER TABLE lab_dip.info ALTER COLUMN id DROP DEFAULT;
       lab_dip          postgres    false    240    239            �           2604    18516 	   recipe id    DEFAULT     h   ALTER TABLE ONLY lab_dip.recipe ALTER COLUMN id SET DEFAULT nextval('lab_dip.recipe_id_seq'::regclass);
 9   ALTER TABLE lab_dip.recipe ALTER COLUMN id DROP DEFAULT;
       lab_dip          postgres    false    243    241            A           2604    18517    batch id    DEFAULT     d   ALTER TABLE ONLY zipper.batch ALTER COLUMN id SET DEFAULT nextval('zipper.batch_id_seq'::regclass);
 7   ALTER TABLE zipper.batch ALTER COLUMN id DROP DEFAULT;
       zipper          postgres    false    284    282            H           2604    18518    dying_batch id    DEFAULT     p   ALTER TABLE ONLY zipper.dying_batch ALTER COLUMN id SET DEFAULT nextval('zipper.dying_batch_id_seq'::regclass);
 =   ALTER TABLE zipper.dying_batch ALTER COLUMN id DROP DEFAULT;
       zipper          postgres    false    289    287            �          0    18014    bank 
   TABLE DATA           �   COPY commercial.bank (uuid, name, swift_code, address, policy, created_at, updated_at, remarks, created_by, routing_no) FROM stdin;
 
   commercial          postgres    false    225   �      �          0    18020    lc 
   TABLE DATA           �  COPY commercial.lc (uuid, party_uuid, lc_number, lc_date, payment_value, payment_date, ldbc_fdbc, acceptance_date, maturity_date, commercial_executive, party_bank, production_complete, lc_cancel, handover_date, shipment_date, expiry_date, ud_no, ud_received, at_sight, amd_date, amd_count, problematical, epz, created_by, created_at, updated_at, remarks, id, document_receive_date, is_rtgs) FROM stdin;
 
   commercial          postgres    false    227   �      9          0    81989    pi_cash 
   TABLE DATA             COPY commercial.pi_cash (uuid, id, lc_uuid, order_info_uuids, marketing_uuid, party_uuid, merchandiser_uuid, factory_uuid, bank_uuid, validity, payment, is_pi, conversion_rate, receive_amount, created_by, created_at, updated_at, remarks, weight, thread_order_info_uuids) FROM stdin;
 
   commercial          postgres    false    308         :          0    82002    pi_cash_entry 
   TABLE DATA           �   COPY commercial.pi_cash_entry (uuid, pi_cash_uuid, sfg_uuid, pi_cash_quantity, created_at, updated_at, remarks, thread_order_entry_uuid) FROM stdin;
 
   commercial          postgres    false    309   �      �          0    18044    challan 
   TABLE DATA           �   COPY delivery.challan (uuid, carton_quantity, assign_to, receive_status, created_by, created_at, updated_at, remarks, id, gate_pass, order_info_uuid) FROM stdin;
    delivery          postgres    false    229   �!      �          0    18050    challan_entry 
   TABLE DATA           q   COPY delivery.challan_entry (uuid, challan_uuid, packing_list_uuid, created_at, updated_at, remarks) FROM stdin;
    delivery          postgres    false    230   �"      �          0    18055    packing_list 
   TABLE DATA           �   COPY delivery.packing_list (uuid, carton_size, carton_weight, created_by, created_at, updated_at, remarks, order_info_uuid, id, challan_uuid) FROM stdin;
    delivery          postgres    false    231   1$      �          0    18060    packing_list_entry 
   TABLE DATA           �   COPY delivery.packing_list_entry (uuid, packing_list_uuid, sfg_uuid, quantity, created_at, updated_at, remarks, short_quantity, reject_quantity) FROM stdin;
    delivery          postgres    false    232   �%      �          0    18065    migrations_details 
   TABLE DATA           C   COPY drizzle.migrations_details (id, hash, created_at) FROM stdin;
    drizzle          postgres    false    233   "'      �          0    18071 
   department 
   TABLE DATA           S   COPY hr.department (uuid, department, created_at, updated_at, remarks) FROM stdin;
    hr          postgres    false    235   �>      �          0    18076    designation 
   TABLE DATA           f   COPY hr.designation (uuid, department_uuid, designation, created_at, updated_at, remarks) FROM stdin;
    hr          postgres    false    236   �@      �          0    18081    policy_and_notice 
   TABLE DATA              COPY hr.policy_and_notice (uuid, type, title, sub_title, url, created_at, updated_at, status, remarks, created_by) FROM stdin;
    hr          postgres    false    237   �C      �          0    18086    users 
   TABLE DATA           �   COPY hr.users (uuid, name, email, pass, designation_uuid, can_access, ext, phone, created_at, updated_at, status, remarks) FROM stdin;
    hr          postgres    false    238   D      �          0    18092    info 
   TABLE DATA           �   COPY lab_dip.info (uuid, id, name, order_info_uuid, created_by, created_at, updated_at, remarks, lab_status, thread_order_info_uuid) FROM stdin;
    lab_dip          postgres    false    239   XX      �          0    18099    recipe 
   TABLE DATA           �   COPY lab_dip.recipe (uuid, id, lab_dip_info_uuid, name, approved, created_by, status, created_at, updated_at, remarks, sub_streat, bleaching) FROM stdin;
    lab_dip          postgres    false    241   _      �          0    18106    recipe_entry 
   TABLE DATA           {   COPY lab_dip.recipe_entry (uuid, recipe_uuid, color, quantity, created_at, updated_at, remarks, material_uuid) FROM stdin;
    lab_dip          postgres    false    242   d      �          0    18113    shade_recipe 
   TABLE DATA           �   COPY lab_dip.shade_recipe (uuid, id, name, sub_streat, lab_status, created_by, created_at, updated_at, remarks, bleaching) FROM stdin;
    lab_dip          postgres    false    245   �j      �          0    18120    shade_recipe_entry 
   TABLE DATA           �   COPY lab_dip.shade_recipe_entry (uuid, shade_recipe_uuid, material_uuid, quantity, created_at, updated_at, remarks) FROM stdin;
    lab_dip          postgres    false    246   5k      �          0    18125    info 
   TABLE DATA           �   COPY material.info (uuid, section_uuid, type_uuid, name, short_name, unit, threshold, description, created_at, updated_at, remarks, created_by) FROM stdin;
    material          postgres    false    247   l      �          0    18131    section 
   TABLE DATA           h   COPY material.section (uuid, name, short_name, remarks, created_at, updated_at, created_by) FROM stdin;
    material          postgres    false    248   �o      �          0    18136    stock 
   TABLE DATA           �  COPY material.stock (uuid, material_uuid, stock, tape_making, coil_forming, dying_and_iron, m_gapping, v_gapping, v_teeth_molding, m_teeth_molding, teeth_assembling_and_polishing, m_teeth_cleaning, v_teeth_cleaning, plating_and_iron, m_sealing, v_sealing, n_t_cutting, v_t_cutting, m_stopper, v_stopper, n_stopper, cutting, die_casting, slider_assembly, coloring, remarks, lab_dip, m_qc_and_packing, v_qc_and_packing, n_qc_and_packing, s_qc_and_packing) FROM stdin;
    material          postgres    false    249   �p      �          0    18169    stock_to_sfg 
   TABLE DATA           �   COPY material.stock_to_sfg (uuid, material_uuid, order_entry_uuid, trx_to, trx_quantity, created_by, created_at, updated_at, remarks) FROM stdin;
    material          postgres    false    250   Yr                 0    18174    trx 
   TABLE DATA           w   COPY material.trx (uuid, material_uuid, trx_to, trx_quantity, created_by, created_at, updated_at, remarks) FROM stdin;
    material          postgres    false    251   vr                0    18179    type 
   TABLE DATA           e   COPY material.type (uuid, name, short_name, remarks, created_at, updated_at, created_by) FROM stdin;
    material          postgres    false    252   �v                0    18184    used 
   TABLE DATA           �   COPY material.used (uuid, material_uuid, section, used_quantity, wastage, created_by, created_at, updated_at, remarks) FROM stdin;
    material          postgres    false    253   Jw                0    18190    buyer 
   TABLE DATA           d   COPY public.buyer (uuid, name, short_name, remarks, created_at, updated_at, created_by) FROM stdin;
    public          postgres    false    254   �y                0    18195    factory 
   TABLE DATA           v   COPY public.factory (uuid, party_uuid, name, phone, address, created_at, updated_at, created_by, remarks) FROM stdin;
    public          postgres    false    255   һ      6          0    73775    machine 
   TABLE DATA           �   COPY public.machine (uuid, name, is_vislon, is_metal, is_nylon, is_sewing_thread, is_bulk, is_sample, min_capacity, max_capacity, water_capacity, created_by, created_at, updated_at, remarks) FROM stdin;
    public          postgres    false    305   .�                0    18200 	   marketing 
   TABLE DATA           s   COPY public.marketing (uuid, name, short_name, user_uuid, remarks, created_at, updated_at, created_by) FROM stdin;
    public          postgres    false    256   ��                0    18205    merchandiser 
   TABLE DATA           �   COPY public.merchandiser (uuid, party_uuid, name, email, phone, address, created_at, updated_at, created_by, remarks) FROM stdin;
    public          postgres    false    257   ��                0    18210    party 
   TABLE DATA           m   COPY public.party (uuid, name, short_name, remarks, created_at, updated_at, created_by, address) FROM stdin;
    public          postgres    false    258   �H                0    18215 
   properties 
   TABLE DATA           y   COPY public.properties (uuid, item_for, type, name, short_name, created_by, created_at, updated_at, remarks) FROM stdin;
    public          postgres    false    259   �|      	          0    18220    section 
   TABLE DATA           B   COPY public.section (uuid, name, short_name, remarks) FROM stdin;
    public          postgres    false    260   ��                0    18226    description 
   TABLE DATA           �   COPY purchase.description (uuid, vendor_uuid, is_local, lc_number, created_by, created_at, updated_at, remarks, id, challan_number) FROM stdin;
    purchase          postgres    false    262   ��                0    18232    entry 
   TABLE DATA           �   COPY purchase.entry (uuid, purchase_description_uuid, material_uuid, quantity, price, created_at, updated_at, remarks) FROM stdin;
    purchase          postgres    false    263   �                0    18238    vendor 
   TABLE DATA           �   COPY purchase.vendor (uuid, name, contact_name, email, office_address, contact_number, remarks, created_at, updated_at, created_by) FROM stdin;
    purchase          postgres    false    264   ��      7          0    73799    assembly_stock 
   TABLE DATA           �   COPY slider.assembly_stock (uuid, name, die_casting_body_uuid, die_casting_puller_uuid, die_casting_cap_uuid, die_casting_link_uuid, quantity, created_by, created_at, updated_at, remarks, weight) FROM stdin;
    slider          postgres    false    306   �                0    18243    coloring_transaction 
   TABLE DATA           �   COPY slider.coloring_transaction (uuid, stock_uuid, order_info_uuid, trx_quantity, created_by, created_at, updated_at, remarks, weight) FROM stdin;
    slider          postgres    false    265   :�                0    18248    die_casting 
   TABLE DATA           �   COPY slider.die_casting (uuid, name, item, zipper_number, end_type, puller_type, logo_type, slider_body_shape, slider_link, quantity, weight, pcs_per_kg, created_at, updated_at, remarks, quantity_in_sa, is_logo_body, is_logo_puller, type) FROM stdin;
    slider          postgres    false    266   W�                0    18259    die_casting_production 
   TABLE DATA           �   COPY slider.die_casting_production (uuid, die_casting_uuid, mc_no, cavity_goods, cavity_defect, push, weight, order_description_uuid, created_by, created_at, updated_at, remarks) FROM stdin;
    slider          postgres    false    267   f�      8          0    81937    die_casting_to_assembly_stock 
   TABLE DATA           �   COPY slider.die_casting_to_assembly_stock (uuid, assembly_stock_uuid, production_quantity, wastage, created_by, created_at, updated_at, remarks, with_link, weight) FROM stdin;
    slider          postgres    false    307   �                0    18264    die_casting_transaction 
   TABLE DATA           �   COPY slider.die_casting_transaction (uuid, die_casting_uuid, stock_uuid, trx_quantity, created_by, created_at, updated_at, remarks, weight) FROM stdin;
    slider          postgres    false    268   З                0    18269 
   production 
   TABLE DATA           �   COPY slider.production (uuid, stock_uuid, production_quantity, wastage, section, created_by, created_at, updated_at, remarks, with_link, weight) FROM stdin;
    slider          postgres    false    269   ��                0    18274    stock 
   TABLE DATA           Q  COPY slider.stock (uuid, order_quantity, body_quantity, cap_quantity, puller_quantity, link_quantity, sa_prod, coloring_stock, coloring_prod, trx_to_finishing, u_top_quantity, h_bottom_quantity, box_pin_quantity, two_way_pin_quantity, created_at, updated_at, remarks, quantity_in_sa, order_description_uuid, finishing_stock) FROM stdin;
    slider          postgres    false    270   �                0    18293    transaction 
   TABLE DATA           �   COPY slider.transaction (uuid, stock_uuid, trx_quantity, created_by, created_at, updated_at, remarks, from_section, to_section, assembly_stock_uuid, weight) FROM stdin;
    slider          postgres    false    271   =�                0    18298    trx_against_stock 
   TABLE DATA           �   COPY slider.trx_against_stock (uuid, die_casting_uuid, quantity, created_by, created_at, updated_at, remarks, weight) FROM stdin;
    slider          postgres    false    272   t�                0    18304    batch 
   TABLE DATA             COPY thread.batch (uuid, id, dyeing_operator, reason, category, status, pass_by, shift, dyeing_supervisor, coning_operator, coning_supervisor, coning_machines, created_by, created_at, updated_at, remarks, yarn_quantity, machine_uuid, lab_created_by, lab_created_at, lab_updated_at, yarn_issue_created_by, yarn_issue_created_at, yarn_issue_updated_at, is_drying_complete, drying_created_at, drying_updated_at, dyeing_created_by, dyeing_created_at, dyeing_updated_at, coning_created_by, coning_created_at, coning_updated_at, slot) FROM stdin;
    thread          postgres    false    274   ��                0    18311    batch_entry 
   TABLE DATA           �   COPY thread.batch_entry (uuid, batch_uuid, order_entry_uuid, quantity, coning_production_quantity, coning_carton_quantity, created_at, updated_at, remarks, coning_created_at, coning_updated_at, transfer_quantity, transfer_carton_quantity) FROM stdin;
    thread          postgres    false    275   2�      >          0    131188    batch_entry_production 
   TABLE DATA           �   COPY thread.batch_entry_production (uuid, batch_entry_uuid, production_quantity, coning_carton_quantity, created_by, created_at, updated_at, remarks) FROM stdin;
    thread          postgres    false    314   ��      ?          0    131195    batch_entry_trx 
   TABLE DATA           �   COPY thread.batch_entry_trx (uuid, batch_entry_uuid, quantity, created_by, created_at, updated_at, remarks, carton_quantity) FROM stdin;
    thread          postgres    false    315   �      @          0    131202    challan 
   TABLE DATA           �   COPY thread.challan (uuid, order_info_uuid, carton_quantity, created_by, created_at, updated_at, remarks, assign_to, gate_pass, received) FROM stdin;
    thread          postgres    false    316   /�      A          0    131209    challan_entry 
   TABLE DATA           �   COPY thread.challan_entry (uuid, challan_uuid, order_entry_uuid, quantity, created_by, created_at, updated_at, remarks, carton_quantity, short_quantity, reject_quantity) FROM stdin;
    thread          postgres    false    317   L�                0    18320    count_length 
   TABLE DATA           �   COPY thread.count_length (uuid, count, sst, created_by, created_at, updated_at, remarks, min_weight, max_weight, length, price, cone_per_carton) FROM stdin;
    thread          postgres    false    276   i�                0    18325    dyes_category 
   TABLE DATA           �   COPY thread.dyes_category (uuid, name, upto_percentage, bleaching, id, created_by, created_at, updated_at, remarks) FROM stdin;
    thread          postgres    false    277   x�                0    18338    order_entry 
   TABLE DATA           �  COPY thread.order_entry (uuid, order_info_uuid, lab_reference, color, po, style, count_length_uuid, quantity, company_price, party_price, swatch_approval_date, production_quantity, created_by, created_at, updated_at, remarks, bleaching, transfer_quantity, recipe_uuid, pi, delivered, warehouse, short_quantity, reject_quantity, production_quantity_in_kg, carton_quantity) FROM stdin;
    thread          postgres    false    278   ��                0    18348 
   order_info 
   TABLE DATA           �   COPY thread.order_info (uuid, id, party_uuid, marketing_uuid, factory_uuid, merchandiser_uuid, buyer_uuid, is_sample, is_bill, delivery_date, created_by, created_at, updated_at, remarks, is_cash) FROM stdin;
    thread          postgres    false    280   �                0    18356    programs 
   TABLE DATA           �   COPY thread.programs (uuid, dyes_category_uuid, material_uuid, quantity, created_by, created_at, updated_at, remarks) FROM stdin;
    thread          postgres    false    281   ��                0    18362    batch 
   TABLE DATA           �   COPY zipper.batch (uuid, id, created_by, created_at, updated_at, remarks, batch_status, machine_uuid, slot, received) FROM stdin;
    zipper          postgres    false    282   z�                 0    18368    batch_entry 
   TABLE DATA           �   COPY zipper.batch_entry (uuid, batch_uuid, quantity, production_quantity, production_quantity_in_kg, created_at, updated_at, remarks, sfg_uuid) FROM stdin;
    zipper          postgres    false    283   ��      "          0    18377    batch_production 
   TABLE DATA           �   COPY zipper.batch_production (uuid, batch_entry_uuid, production_quantity, production_quantity_in_kg, created_by, created_at, updated_at, remarks) FROM stdin;
    zipper          postgres    false    285   ��      #          0    18382    dyed_tape_transaction 
   TABLE DATA           �   COPY zipper.dyed_tape_transaction (uuid, order_description_uuid, colors, trx_quantity, created_by, created_at, updated_at, remarks) FROM stdin;
    zipper          postgres    false    286   -�      =          0    131078     dyed_tape_transaction_from_stock 
   TABLE DATA           �   COPY zipper.dyed_tape_transaction_from_stock (uuid, order_description_uuid, trx_quantity, tape_coil_uuid, created_by, created_at, updated_at, remarks) FROM stdin;
    zipper          postgres    false    313   ��      $          0    18387    dying_batch 
   TABLE DATA           c   COPY zipper.dying_batch (uuid, id, mc_no, created_by, created_at, updated_at, remarks) FROM stdin;
    zipper          postgres    false    287   �      %          0    18392    dying_batch_entry 
   TABLE DATA           �   COPY zipper.dying_batch_entry (uuid, dying_batch_uuid, batch_entry_uuid, quantity, production_quantity, production_quantity_in_kg, created_at, updated_at, remarks) FROM stdin;
    zipper          postgres    false    288   �      '          0    18398 &   material_trx_against_order_description 
   TABLE DATA           �   COPY zipper.material_trx_against_order_description (uuid, order_description_uuid, material_uuid, trx_to, trx_quantity, created_by, created_at, updated_at, remarks) FROM stdin;
    zipper          postgres    false    290   -�      (          0    18403    order_description 
   TABLE DATA           J  COPY zipper.order_description (uuid, order_info_uuid, item, zipper_number, end_type, lock_type, puller_type, teeth_color, puller_color, special_requirement, hand, coloring_type, is_slider_provided, slider, slider_starting_section_enum, top_stopper, bottom_stopper, logo_type, is_logo_body, is_logo_puller, description, status, created_at, updated_at, remarks, slider_body_shape, slider_link, end_user, garment, light_preference, garments_wash, created_by, garments_remarks, tape_received, tape_transferred, slider_finishing_stock, nylon_stopper, tape_coil_uuid, teeth_type) FROM stdin;
    zipper          postgres    false    291   J�      )          0    18418    order_entry 
   TABLE DATA           �   COPY zipper.order_entry (uuid, order_description_uuid, style, color, size, quantity, company_price, party_price, status, swatch_status_enum, swatch_approval_date, created_at, updated_at, remarks, bleaching) FROM stdin;
    zipper          postgres    false    292   ��      +          0    18428 
   order_info 
   TABLE DATA           %  COPY zipper.order_info (uuid, id, reference_order_info_uuid, buyer_uuid, party_uuid, marketing_uuid, merchandiser_uuid, factory_uuid, is_sample, is_bill, is_cash, marketing_priority, factory_priority, status, created_by, created_at, updated_at, remarks, conversion_rate, print_in) FROM stdin;
    zipper          postgres    false    294   H�      ,          0    18438    planning 
   TABLE DATA           U   COPY zipper.planning (week, created_by, created_at, updated_at, remarks) FROM stdin;
    zipper          postgres    false    295   "�      -          0    18443    planning_entry 
   TABLE DATA           �   COPY zipper.planning_entry (uuid, sfg_uuid, sno_quantity, factory_quantity, production_quantity, batch_production_quantity, created_at, updated_at, planning_week, sno_remarks, factory_remarks) FROM stdin;
    zipper          postgres    false    296   ?�      .          0    18452    sfg 
   TABLE DATA             COPY zipper.sfg (uuid, order_entry_uuid, recipe_uuid, dying_and_iron_prod, teeth_molding_stock, teeth_molding_prod, teeth_coloring_stock, teeth_coloring_prod, finishing_stock, finishing_prod, coloring_prod, warehouse, delivered, pi, remarks, short_quantity, reject_quantity) FROM stdin;
    zipper          postgres    false    297   \�      /          0    18468    sfg_production 
   TABLE DATA           �   COPY zipper.sfg_production (uuid, sfg_uuid, section, production_quantity_in_kg, production_quantity, wastage, created_by, created_at, updated_at, remarks) FROM stdin;
    zipper          postgres    false    298   U�      0          0    18476    sfg_transaction 
   TABLE DATA           �   COPY zipper.sfg_transaction (uuid, trx_from, trx_to, trx_quantity, slider_item_uuid, created_by, created_at, updated_at, remarks, sfg_uuid, trx_quantity_in_kg) FROM stdin;
    zipper          postgres    false    299   ��      1          0    18483 	   tape_coil 
   TABLE DATA             COPY zipper.tape_coil (uuid, quantity, trx_quantity_in_coil, quantity_in_coil, remarks, item_uuid, zipper_number_uuid, name, raw_per_kg_meter, dyed_per_kg_meter, created_by, created_at, updated_at, is_import, is_reverse, trx_quantity_in_dying, stock_quantity) FROM stdin;
    zipper          postgres    false    300   .�      2          0    18488    tape_coil_production 
   TABLE DATA           �   COPY zipper.tape_coil_production (uuid, section, tape_coil_uuid, production_quantity, wastage, created_by, created_at, updated_at, remarks) FROM stdin;
    zipper          postgres    false    301   3�      5          0    65568    tape_coil_required 
   TABLE DATA           �   COPY zipper.tape_coil_required (uuid, end_type_uuid, item_uuid, nylon_stopper_uuid, zipper_number_uuid, top, bottom, created_by, created_at, updated_at, remarks) FROM stdin;
    zipper          postgres    false    304   _�      3          0    18494    tape_coil_to_dyeing 
   TABLE DATA           �   COPY zipper.tape_coil_to_dyeing (uuid, tape_coil_uuid, order_description_uuid, trx_quantity, created_by, created_at, updated_at, remarks) FROM stdin;
    zipper          postgres    false    302   ��      4          0    18499    tape_trx 
   TABLE DATA              COPY zipper.tape_trx (uuid, tape_coil_uuid, trx_quantity, created_by, created_at, updated_at, remarks, to_section) FROM stdin;
    zipper          postgres    false    303   �      M           0    0    lc_sequence    SEQUENCE SET     >   SELECT pg_catalog.setval('commercial.lc_sequence', 10, true);
       
   commercial          postgres    false    226            N           0    0    pi_sequence    SEQUENCE SET     >   SELECT pg_catalog.setval('commercial.pi_sequence', 38, true);
       
   commercial          postgres    false    228            O           0    0    challan_sequence    SEQUENCE SET     @   SELECT pg_catalog.setval('delivery.challan_sequence', 7, true);
          delivery          postgres    false    312            P           0    0    packing_list_sequence    SEQUENCE SET     F   SELECT pg_catalog.setval('delivery.packing_list_sequence', 10, true);
          delivery          postgres    false    310            Q           0    0    migrations_details_id_seq    SEQUENCE SET     J   SELECT pg_catalog.setval('drizzle.migrations_details_id_seq', 131, true);
          drizzle          postgres    false    234            R           0    0    info_id_seq    SEQUENCE SET     <   SELECT pg_catalog.setval('lab_dip.info_id_seq', 144, true);
          lab_dip          postgres    false    240            S           0    0    recipe_id_seq    SEQUENCE SET     =   SELECT pg_catalog.setval('lab_dip.recipe_id_seq', 31, true);
          lab_dip          postgres    false    243            T           0    0    shade_recipe_sequence    SEQUENCE SET     E   SELECT pg_catalog.setval('lab_dip.shade_recipe_sequence', 12, true);
          lab_dip          postgres    false    244            U           0    0    purchase_description_sequence    SEQUENCE SET     N   SELECT pg_catalog.setval('purchase.purchase_description_sequence', 13, true);
          purchase          postgres    false    261            V           0    0    thread_batch_sequence    SEQUENCE SET     D   SELECT pg_catalog.setval('thread.thread_batch_sequence', 27, true);
          thread          postgres    false    273            W           0    0    thread_order_info_sequence    SEQUENCE SET     H   SELECT pg_catalog.setval('thread.thread_order_info_sequence', 9, true);
          thread          postgres    false    279            X           0    0    batch_id_seq    SEQUENCE SET     ;   SELECT pg_catalog.setval('zipper.batch_id_seq', 14, true);
          zipper          postgres    false    284            Y           0    0    dying_batch_id_seq    SEQUENCE SET     A   SELECT pg_catalog.setval('zipper.dying_batch_id_seq', 1, false);
          zipper          postgres    false    289            Z           0    0    order_info_sequence    SEQUENCE SET     B   SELECT pg_catalog.setval('zipper.order_info_sequence', 26, true);
          zipper          postgres    false    293            �           2606    18520    bank bank_pkey 
   CONSTRAINT     R   ALTER TABLE ONLY commercial.bank
    ADD CONSTRAINT bank_pkey PRIMARY KEY (uuid);
 <   ALTER TABLE ONLY commercial.bank DROP CONSTRAINT bank_pkey;
    
   commercial            postgres    false    225            �           2606    18522 
   lc lc_pkey 
   CONSTRAINT     N   ALTER TABLE ONLY commercial.lc
    ADD CONSTRAINT lc_pkey PRIMARY KEY (uuid);
 8   ALTER TABLE ONLY commercial.lc DROP CONSTRAINT lc_pkey;
    
   commercial            postgres    false    227            0           2606    82008     pi_cash_entry pi_cash_entry_pkey 
   CONSTRAINT     d   ALTER TABLE ONLY commercial.pi_cash_entry
    ADD CONSTRAINT pi_cash_entry_pkey PRIMARY KEY (uuid);
 N   ALTER TABLE ONLY commercial.pi_cash_entry DROP CONSTRAINT pi_cash_entry_pkey;
    
   commercial            postgres    false    309            .           2606    82001    pi_cash pi_cash_pkey 
   CONSTRAINT     X   ALTER TABLE ONLY commercial.pi_cash
    ADD CONSTRAINT pi_cash_pkey PRIMARY KEY (uuid);
 B   ALTER TABLE ONLY commercial.pi_cash DROP CONSTRAINT pi_cash_pkey;
    
   commercial            postgres    false    308            �           2606    18528     challan_entry challan_entry_pkey 
   CONSTRAINT     b   ALTER TABLE ONLY delivery.challan_entry
    ADD CONSTRAINT challan_entry_pkey PRIMARY KEY (uuid);
 L   ALTER TABLE ONLY delivery.challan_entry DROP CONSTRAINT challan_entry_pkey;
       delivery            postgres    false    230            �           2606    18530    challan challan_pkey 
   CONSTRAINT     V   ALTER TABLE ONLY delivery.challan
    ADD CONSTRAINT challan_pkey PRIMARY KEY (uuid);
 @   ALTER TABLE ONLY delivery.challan DROP CONSTRAINT challan_pkey;
       delivery            postgres    false    229            �           2606    18532 *   packing_list_entry packing_list_entry_pkey 
   CONSTRAINT     l   ALTER TABLE ONLY delivery.packing_list_entry
    ADD CONSTRAINT packing_list_entry_pkey PRIMARY KEY (uuid);
 V   ALTER TABLE ONLY delivery.packing_list_entry DROP CONSTRAINT packing_list_entry_pkey;
       delivery            postgres    false    232            �           2606    18534    packing_list packing_list_pkey 
   CONSTRAINT     `   ALTER TABLE ONLY delivery.packing_list
    ADD CONSTRAINT packing_list_pkey PRIMARY KEY (uuid);
 J   ALTER TABLE ONLY delivery.packing_list DROP CONSTRAINT packing_list_pkey;
       delivery            postgres    false    231            �           2606    18536 *   migrations_details migrations_details_pkey 
   CONSTRAINT     i   ALTER TABLE ONLY drizzle.migrations_details
    ADD CONSTRAINT migrations_details_pkey PRIMARY KEY (id);
 U   ALTER TABLE ONLY drizzle.migrations_details DROP CONSTRAINT migrations_details_pkey;
       drizzle            postgres    false    233            �           2606    18538    department department_pkey 
   CONSTRAINT     V   ALTER TABLE ONLY hr.department
    ADD CONSTRAINT department_pkey PRIMARY KEY (uuid);
 @   ALTER TABLE ONLY hr.department DROP CONSTRAINT department_pkey;
       hr            postgres    false    235            �           2606    18540    designation designation_pkey 
   CONSTRAINT     X   ALTER TABLE ONLY hr.designation
    ADD CONSTRAINT designation_pkey PRIMARY KEY (uuid);
 B   ALTER TABLE ONLY hr.designation DROP CONSTRAINT designation_pkey;
       hr            postgres    false    236            �           2606    18542 (   policy_and_notice policy_and_notice_pkey 
   CONSTRAINT     d   ALTER TABLE ONLY hr.policy_and_notice
    ADD CONSTRAINT policy_and_notice_pkey PRIMARY KEY (uuid);
 N   ALTER TABLE ONLY hr.policy_and_notice DROP CONSTRAINT policy_and_notice_pkey;
       hr            postgres    false    237            �           2606    18544    users users_email_unique 
   CONSTRAINT     P   ALTER TABLE ONLY hr.users
    ADD CONSTRAINT users_email_unique UNIQUE (email);
 >   ALTER TABLE ONLY hr.users DROP CONSTRAINT users_email_unique;
       hr            postgres    false    238            �           2606    18546    users users_pkey 
   CONSTRAINT     L   ALTER TABLE ONLY hr.users
    ADD CONSTRAINT users_pkey PRIMARY KEY (uuid);
 6   ALTER TABLE ONLY hr.users DROP CONSTRAINT users_pkey;
       hr            postgres    false    238            �           2606    18548    info info_pkey 
   CONSTRAINT     O   ALTER TABLE ONLY lab_dip.info
    ADD CONSTRAINT info_pkey PRIMARY KEY (uuid);
 9   ALTER TABLE ONLY lab_dip.info DROP CONSTRAINT info_pkey;
       lab_dip            postgres    false    239            �           2606    18550    recipe_entry recipe_entry_pkey 
   CONSTRAINT     _   ALTER TABLE ONLY lab_dip.recipe_entry
    ADD CONSTRAINT recipe_entry_pkey PRIMARY KEY (uuid);
 I   ALTER TABLE ONLY lab_dip.recipe_entry DROP CONSTRAINT recipe_entry_pkey;
       lab_dip            postgres    false    242            �           2606    18552    recipe recipe_pkey 
   CONSTRAINT     S   ALTER TABLE ONLY lab_dip.recipe
    ADD CONSTRAINT recipe_pkey PRIMARY KEY (uuid);
 =   ALTER TABLE ONLY lab_dip.recipe DROP CONSTRAINT recipe_pkey;
       lab_dip            postgres    false    241            �           2606    18554 *   shade_recipe_entry shade_recipe_entry_pkey 
   CONSTRAINT     k   ALTER TABLE ONLY lab_dip.shade_recipe_entry
    ADD CONSTRAINT shade_recipe_entry_pkey PRIMARY KEY (uuid);
 U   ALTER TABLE ONLY lab_dip.shade_recipe_entry DROP CONSTRAINT shade_recipe_entry_pkey;
       lab_dip            postgres    false    246            �           2606    18556    shade_recipe shade_recipe_pkey 
   CONSTRAINT     _   ALTER TABLE ONLY lab_dip.shade_recipe
    ADD CONSTRAINT shade_recipe_pkey PRIMARY KEY (uuid);
 I   ALTER TABLE ONLY lab_dip.shade_recipe DROP CONSTRAINT shade_recipe_pkey;
       lab_dip            postgres    false    245            �           2606    18558    info info_pkey 
   CONSTRAINT     P   ALTER TABLE ONLY material.info
    ADD CONSTRAINT info_pkey PRIMARY KEY (uuid);
 :   ALTER TABLE ONLY material.info DROP CONSTRAINT info_pkey;
       material            postgres    false    247            �           2606    18560    section section_pkey 
   CONSTRAINT     V   ALTER TABLE ONLY material.section
    ADD CONSTRAINT section_pkey PRIMARY KEY (uuid);
 @   ALTER TABLE ONLY material.section DROP CONSTRAINT section_pkey;
       material            postgres    false    248            �           2606    18562    stock stock_pkey 
   CONSTRAINT     R   ALTER TABLE ONLY material.stock
    ADD CONSTRAINT stock_pkey PRIMARY KEY (uuid);
 <   ALTER TABLE ONLY material.stock DROP CONSTRAINT stock_pkey;
       material            postgres    false    249            �           2606    18564    stock_to_sfg stock_to_sfg_pkey 
   CONSTRAINT     `   ALTER TABLE ONLY material.stock_to_sfg
    ADD CONSTRAINT stock_to_sfg_pkey PRIMARY KEY (uuid);
 J   ALTER TABLE ONLY material.stock_to_sfg DROP CONSTRAINT stock_to_sfg_pkey;
       material            postgres    false    250            �           2606    18566    trx trx_pkey 
   CONSTRAINT     N   ALTER TABLE ONLY material.trx
    ADD CONSTRAINT trx_pkey PRIMARY KEY (uuid);
 8   ALTER TABLE ONLY material.trx DROP CONSTRAINT trx_pkey;
       material            postgres    false    251            �           2606    18568    type type_pkey 
   CONSTRAINT     P   ALTER TABLE ONLY material.type
    ADD CONSTRAINT type_pkey PRIMARY KEY (uuid);
 :   ALTER TABLE ONLY material.type DROP CONSTRAINT type_pkey;
       material            postgres    false    252            �           2606    18570    used used_pkey 
   CONSTRAINT     P   ALTER TABLE ONLY material.used
    ADD CONSTRAINT used_pkey PRIMARY KEY (uuid);
 :   ALTER TABLE ONLY material.used DROP CONSTRAINT used_pkey;
       material            postgres    false    253            �           2606    18572    buyer buyer_name_unique 
   CONSTRAINT     R   ALTER TABLE ONLY public.buyer
    ADD CONSTRAINT buyer_name_unique UNIQUE (name);
 A   ALTER TABLE ONLY public.buyer DROP CONSTRAINT buyer_name_unique;
       public            postgres    false    254            �           2606    18574    buyer buyer_pkey 
   CONSTRAINT     P   ALTER TABLE ONLY public.buyer
    ADD CONSTRAINT buyer_pkey PRIMARY KEY (uuid);
 :   ALTER TABLE ONLY public.buyer DROP CONSTRAINT buyer_pkey;
       public            postgres    false    254            �           2606    18576    factory factory_name_unique 
   CONSTRAINT     V   ALTER TABLE ONLY public.factory
    ADD CONSTRAINT factory_name_unique UNIQUE (name);
 E   ALTER TABLE ONLY public.factory DROP CONSTRAINT factory_name_unique;
       public            postgres    false    255            �           2606    18578    factory factory_pkey 
   CONSTRAINT     T   ALTER TABLE ONLY public.factory
    ADD CONSTRAINT factory_pkey PRIMARY KEY (uuid);
 >   ALTER TABLE ONLY public.factory DROP CONSTRAINT factory_pkey;
       public            postgres    false    255            (           2606    73788    machine machine_pkey 
   CONSTRAINT     T   ALTER TABLE ONLY public.machine
    ADD CONSTRAINT machine_pkey PRIMARY KEY (uuid);
 >   ALTER TABLE ONLY public.machine DROP CONSTRAINT machine_pkey;
       public            postgres    false    305            �           2606    18580    marketing marketing_name_unique 
   CONSTRAINT     Z   ALTER TABLE ONLY public.marketing
    ADD CONSTRAINT marketing_name_unique UNIQUE (name);
 I   ALTER TABLE ONLY public.marketing DROP CONSTRAINT marketing_name_unique;
       public            postgres    false    256            �           2606    18582    marketing marketing_pkey 
   CONSTRAINT     X   ALTER TABLE ONLY public.marketing
    ADD CONSTRAINT marketing_pkey PRIMARY KEY (uuid);
 B   ALTER TABLE ONLY public.marketing DROP CONSTRAINT marketing_pkey;
       public            postgres    false    256            �           2606    18584 %   merchandiser merchandiser_name_unique 
   CONSTRAINT     `   ALTER TABLE ONLY public.merchandiser
    ADD CONSTRAINT merchandiser_name_unique UNIQUE (name);
 O   ALTER TABLE ONLY public.merchandiser DROP CONSTRAINT merchandiser_name_unique;
       public            postgres    false    257            �           2606    18586    merchandiser merchandiser_pkey 
   CONSTRAINT     ^   ALTER TABLE ONLY public.merchandiser
    ADD CONSTRAINT merchandiser_pkey PRIMARY KEY (uuid);
 H   ALTER TABLE ONLY public.merchandiser DROP CONSTRAINT merchandiser_pkey;
       public            postgres    false    257            �           2606    18588    party party_name_unique 
   CONSTRAINT     R   ALTER TABLE ONLY public.party
    ADD CONSTRAINT party_name_unique UNIQUE (name);
 A   ALTER TABLE ONLY public.party DROP CONSTRAINT party_name_unique;
       public            postgres    false    258            �           2606    18590    party party_pkey 
   CONSTRAINT     P   ALTER TABLE ONLY public.party
    ADD CONSTRAINT party_pkey PRIMARY KEY (uuid);
 :   ALTER TABLE ONLY public.party DROP CONSTRAINT party_pkey;
       public            postgres    false    258            �           2606    18592    properties properties_pkey 
   CONSTRAINT     Z   ALTER TABLE ONLY public.properties
    ADD CONSTRAINT properties_pkey PRIMARY KEY (uuid);
 D   ALTER TABLE ONLY public.properties DROP CONSTRAINT properties_pkey;
       public            postgres    false    259            �           2606    18594    section section_pkey 
   CONSTRAINT     T   ALTER TABLE ONLY public.section
    ADD CONSTRAINT section_pkey PRIMARY KEY (uuid);
 >   ALTER TABLE ONLY public.section DROP CONSTRAINT section_pkey;
       public            postgres    false    260            �           2606    18596    description description_pkey 
   CONSTRAINT     ^   ALTER TABLE ONLY purchase.description
    ADD CONSTRAINT description_pkey PRIMARY KEY (uuid);
 H   ALTER TABLE ONLY purchase.description DROP CONSTRAINT description_pkey;
       purchase            postgres    false    262            �           2606    18598    entry entry_pkey 
   CONSTRAINT     R   ALTER TABLE ONLY purchase.entry
    ADD CONSTRAINT entry_pkey PRIMARY KEY (uuid);
 <   ALTER TABLE ONLY purchase.entry DROP CONSTRAINT entry_pkey;
       purchase            postgres    false    263            �           2606    18600    vendor vendor_pkey 
   CONSTRAINT     T   ALTER TABLE ONLY purchase.vendor
    ADD CONSTRAINT vendor_pkey PRIMARY KEY (uuid);
 >   ALTER TABLE ONLY purchase.vendor DROP CONSTRAINT vendor_pkey;
       purchase            postgres    false    264            *           2606    73807 "   assembly_stock assembly_stock_pkey 
   CONSTRAINT     b   ALTER TABLE ONLY slider.assembly_stock
    ADD CONSTRAINT assembly_stock_pkey PRIMARY KEY (uuid);
 L   ALTER TABLE ONLY slider.assembly_stock DROP CONSTRAINT assembly_stock_pkey;
       slider            postgres    false    306            �           2606    18602 .   coloring_transaction coloring_transaction_pkey 
   CONSTRAINT     n   ALTER TABLE ONLY slider.coloring_transaction
    ADD CONSTRAINT coloring_transaction_pkey PRIMARY KEY (uuid);
 X   ALTER TABLE ONLY slider.coloring_transaction DROP CONSTRAINT coloring_transaction_pkey;
       slider            postgres    false    265            �           2606    18604    die_casting die_casting_pkey 
   CONSTRAINT     \   ALTER TABLE ONLY slider.die_casting
    ADD CONSTRAINT die_casting_pkey PRIMARY KEY (uuid);
 F   ALTER TABLE ONLY slider.die_casting DROP CONSTRAINT die_casting_pkey;
       slider            postgres    false    266            �           2606    18606 2   die_casting_production die_casting_production_pkey 
   CONSTRAINT     r   ALTER TABLE ONLY slider.die_casting_production
    ADD CONSTRAINT die_casting_production_pkey PRIMARY KEY (uuid);
 \   ALTER TABLE ONLY slider.die_casting_production DROP CONSTRAINT die_casting_production_pkey;
       slider            postgres    false    267            ,           2606    81945 @   die_casting_to_assembly_stock die_casting_to_assembly_stock_pkey 
   CONSTRAINT     �   ALTER TABLE ONLY slider.die_casting_to_assembly_stock
    ADD CONSTRAINT die_casting_to_assembly_stock_pkey PRIMARY KEY (uuid);
 j   ALTER TABLE ONLY slider.die_casting_to_assembly_stock DROP CONSTRAINT die_casting_to_assembly_stock_pkey;
       slider            postgres    false    307            �           2606    18608 4   die_casting_transaction die_casting_transaction_pkey 
   CONSTRAINT     t   ALTER TABLE ONLY slider.die_casting_transaction
    ADD CONSTRAINT die_casting_transaction_pkey PRIMARY KEY (uuid);
 ^   ALTER TABLE ONLY slider.die_casting_transaction DROP CONSTRAINT die_casting_transaction_pkey;
       slider            postgres    false    268            �           2606    18610    production production_pkey 
   CONSTRAINT     Z   ALTER TABLE ONLY slider.production
    ADD CONSTRAINT production_pkey PRIMARY KEY (uuid);
 D   ALTER TABLE ONLY slider.production DROP CONSTRAINT production_pkey;
       slider            postgres    false    269            �           2606    18612    stock stock_pkey 
   CONSTRAINT     P   ALTER TABLE ONLY slider.stock
    ADD CONSTRAINT stock_pkey PRIMARY KEY (uuid);
 :   ALTER TABLE ONLY slider.stock DROP CONSTRAINT stock_pkey;
       slider            postgres    false    270            �           2606    18614    transaction transaction_pkey 
   CONSTRAINT     \   ALTER TABLE ONLY slider.transaction
    ADD CONSTRAINT transaction_pkey PRIMARY KEY (uuid);
 F   ALTER TABLE ONLY slider.transaction DROP CONSTRAINT transaction_pkey;
       slider            postgres    false    271            �           2606    18616 (   trx_against_stock trx_against_stock_pkey 
   CONSTRAINT     h   ALTER TABLE ONLY slider.trx_against_stock
    ADD CONSTRAINT trx_against_stock_pkey PRIMARY KEY (uuid);
 R   ALTER TABLE ONLY slider.trx_against_stock DROP CONSTRAINT trx_against_stock_pkey;
       slider            postgres    false    272            �           2606    18618    batch_entry batch_entry_pkey 
   CONSTRAINT     \   ALTER TABLE ONLY thread.batch_entry
    ADD CONSTRAINT batch_entry_pkey PRIMARY KEY (uuid);
 F   ALTER TABLE ONLY thread.batch_entry DROP CONSTRAINT batch_entry_pkey;
       thread            postgres    false    275            4           2606    131194 2   batch_entry_production batch_entry_production_pkey 
   CONSTRAINT     r   ALTER TABLE ONLY thread.batch_entry_production
    ADD CONSTRAINT batch_entry_production_pkey PRIMARY KEY (uuid);
 \   ALTER TABLE ONLY thread.batch_entry_production DROP CONSTRAINT batch_entry_production_pkey;
       thread            postgres    false    314            6           2606    131201 $   batch_entry_trx batch_entry_trx_pkey 
   CONSTRAINT     d   ALTER TABLE ONLY thread.batch_entry_trx
    ADD CONSTRAINT batch_entry_trx_pkey PRIMARY KEY (uuid);
 N   ALTER TABLE ONLY thread.batch_entry_trx DROP CONSTRAINT batch_entry_trx_pkey;
       thread            postgres    false    315            �           2606    18620    batch batch_pkey 
   CONSTRAINT     P   ALTER TABLE ONLY thread.batch
    ADD CONSTRAINT batch_pkey PRIMARY KEY (uuid);
 :   ALTER TABLE ONLY thread.batch DROP CONSTRAINT batch_pkey;
       thread            postgres    false    274            :           2606    131215     challan_entry challan_entry_pkey 
   CONSTRAINT     `   ALTER TABLE ONLY thread.challan_entry
    ADD CONSTRAINT challan_entry_pkey PRIMARY KEY (uuid);
 J   ALTER TABLE ONLY thread.challan_entry DROP CONSTRAINT challan_entry_pkey;
       thread            postgres    false    317            8           2606    131208    challan challan_pkey 
   CONSTRAINT     T   ALTER TABLE ONLY thread.challan
    ADD CONSTRAINT challan_pkey PRIMARY KEY (uuid);
 >   ALTER TABLE ONLY thread.challan DROP CONSTRAINT challan_pkey;
       thread            postgres    false    316            �           2606    18622 !   count_length count_length_uuid_pk 
   CONSTRAINT     a   ALTER TABLE ONLY thread.count_length
    ADD CONSTRAINT count_length_uuid_pk PRIMARY KEY (uuid);
 K   ALTER TABLE ONLY thread.count_length DROP CONSTRAINT count_length_uuid_pk;
       thread            postgres    false    276            �           2606    18624     dyes_category dyes_category_pkey 
   CONSTRAINT     `   ALTER TABLE ONLY thread.dyes_category
    ADD CONSTRAINT dyes_category_pkey PRIMARY KEY (uuid);
 J   ALTER TABLE ONLY thread.dyes_category DROP CONSTRAINT dyes_category_pkey;
       thread            postgres    false    277            �           2606    18628    order_entry order_entry_pkey 
   CONSTRAINT     \   ALTER TABLE ONLY thread.order_entry
    ADD CONSTRAINT order_entry_pkey PRIMARY KEY (uuid);
 F   ALTER TABLE ONLY thread.order_entry DROP CONSTRAINT order_entry_pkey;
       thread            postgres    false    278            �           2606    18630    order_info order_info_pkey 
   CONSTRAINT     Z   ALTER TABLE ONLY thread.order_info
    ADD CONSTRAINT order_info_pkey PRIMARY KEY (uuid);
 D   ALTER TABLE ONLY thread.order_info DROP CONSTRAINT order_info_pkey;
       thread            postgres    false    280            �           2606    18632    programs programs_pkey 
   CONSTRAINT     V   ALTER TABLE ONLY thread.programs
    ADD CONSTRAINT programs_pkey PRIMARY KEY (uuid);
 @   ALTER TABLE ONLY thread.programs DROP CONSTRAINT programs_pkey;
       thread            postgres    false    281                       2606    18634    batch_entry batch_entry_pkey 
   CONSTRAINT     \   ALTER TABLE ONLY zipper.batch_entry
    ADD CONSTRAINT batch_entry_pkey PRIMARY KEY (uuid);
 F   ALTER TABLE ONLY zipper.batch_entry DROP CONSTRAINT batch_entry_pkey;
       zipper            postgres    false    283                        2606    18636    batch batch_pkey 
   CONSTRAINT     P   ALTER TABLE ONLY zipper.batch
    ADD CONSTRAINT batch_pkey PRIMARY KEY (uuid);
 :   ALTER TABLE ONLY zipper.batch DROP CONSTRAINT batch_pkey;
       zipper            postgres    false    282                       2606    18638 &   batch_production batch_production_pkey 
   CONSTRAINT     f   ALTER TABLE ONLY zipper.batch_production
    ADD CONSTRAINT batch_production_pkey PRIMARY KEY (uuid);
 P   ALTER TABLE ONLY zipper.batch_production DROP CONSTRAINT batch_production_pkey;
       zipper            postgres    false    285            2           2606    131085 F   dyed_tape_transaction_from_stock dyed_tape_transaction_from_stock_pkey 
   CONSTRAINT     �   ALTER TABLE ONLY zipper.dyed_tape_transaction_from_stock
    ADD CONSTRAINT dyed_tape_transaction_from_stock_pkey PRIMARY KEY (uuid);
 p   ALTER TABLE ONLY zipper.dyed_tape_transaction_from_stock DROP CONSTRAINT dyed_tape_transaction_from_stock_pkey;
       zipper            postgres    false    313                       2606    18640 0   dyed_tape_transaction dyed_tape_transaction_pkey 
   CONSTRAINT     p   ALTER TABLE ONLY zipper.dyed_tape_transaction
    ADD CONSTRAINT dyed_tape_transaction_pkey PRIMARY KEY (uuid);
 Z   ALTER TABLE ONLY zipper.dyed_tape_transaction DROP CONSTRAINT dyed_tape_transaction_pkey;
       zipper            postgres    false    286            
           2606    18642 (   dying_batch_entry dying_batch_entry_pkey 
   CONSTRAINT     h   ALTER TABLE ONLY zipper.dying_batch_entry
    ADD CONSTRAINT dying_batch_entry_pkey PRIMARY KEY (uuid);
 R   ALTER TABLE ONLY zipper.dying_batch_entry DROP CONSTRAINT dying_batch_entry_pkey;
       zipper            postgres    false    288                       2606    18644    dying_batch dying_batch_pkey 
   CONSTRAINT     \   ALTER TABLE ONLY zipper.dying_batch
    ADD CONSTRAINT dying_batch_pkey PRIMARY KEY (uuid);
 F   ALTER TABLE ONLY zipper.dying_batch DROP CONSTRAINT dying_batch_pkey;
       zipper            postgres    false    287                       2606    18646 R   material_trx_against_order_description material_trx_against_order_description_pkey 
   CONSTRAINT     �   ALTER TABLE ONLY zipper.material_trx_against_order_description
    ADD CONSTRAINT material_trx_against_order_description_pkey PRIMARY KEY (uuid);
 |   ALTER TABLE ONLY zipper.material_trx_against_order_description DROP CONSTRAINT material_trx_against_order_description_pkey;
       zipper            postgres    false    290                       2606    18648 (   order_description order_description_pkey 
   CONSTRAINT     h   ALTER TABLE ONLY zipper.order_description
    ADD CONSTRAINT order_description_pkey PRIMARY KEY (uuid);
 R   ALTER TABLE ONLY zipper.order_description DROP CONSTRAINT order_description_pkey;
       zipper            postgres    false    291                       2606    18650    order_entry order_entry_pkey 
   CONSTRAINT     \   ALTER TABLE ONLY zipper.order_entry
    ADD CONSTRAINT order_entry_pkey PRIMARY KEY (uuid);
 F   ALTER TABLE ONLY zipper.order_entry DROP CONSTRAINT order_entry_pkey;
       zipper            postgres    false    292                       2606    18652    order_info order_info_pkey 
   CONSTRAINT     Z   ALTER TABLE ONLY zipper.order_info
    ADD CONSTRAINT order_info_pkey PRIMARY KEY (uuid);
 D   ALTER TABLE ONLY zipper.order_info DROP CONSTRAINT order_info_pkey;
       zipper            postgres    false    294                       2606    18654 "   planning_entry planning_entry_pkey 
   CONSTRAINT     b   ALTER TABLE ONLY zipper.planning_entry
    ADD CONSTRAINT planning_entry_pkey PRIMARY KEY (uuid);
 L   ALTER TABLE ONLY zipper.planning_entry DROP CONSTRAINT planning_entry_pkey;
       zipper            postgres    false    296                       2606    18656    planning planning_pkey 
   CONSTRAINT     V   ALTER TABLE ONLY zipper.planning
    ADD CONSTRAINT planning_pkey PRIMARY KEY (week);
 @   ALTER TABLE ONLY zipper.planning DROP CONSTRAINT planning_pkey;
       zipper            postgres    false    295                       2606    18658    sfg sfg_pkey 
   CONSTRAINT     L   ALTER TABLE ONLY zipper.sfg
    ADD CONSTRAINT sfg_pkey PRIMARY KEY (uuid);
 6   ALTER TABLE ONLY zipper.sfg DROP CONSTRAINT sfg_pkey;
       zipper            postgres    false    297                       2606    18660 "   sfg_production sfg_production_pkey 
   CONSTRAINT     b   ALTER TABLE ONLY zipper.sfg_production
    ADD CONSTRAINT sfg_production_pkey PRIMARY KEY (uuid);
 L   ALTER TABLE ONLY zipper.sfg_production DROP CONSTRAINT sfg_production_pkey;
       zipper            postgres    false    298                       2606    18662 $   sfg_transaction sfg_transaction_pkey 
   CONSTRAINT     d   ALTER TABLE ONLY zipper.sfg_transaction
    ADD CONSTRAINT sfg_transaction_pkey PRIMARY KEY (uuid);
 N   ALTER TABLE ONLY zipper.sfg_transaction DROP CONSTRAINT sfg_transaction_pkey;
       zipper            postgres    false    299                       2606    18664    tape_coil tape_coil_pkey 
   CONSTRAINT     X   ALTER TABLE ONLY zipper.tape_coil
    ADD CONSTRAINT tape_coil_pkey PRIMARY KEY (uuid);
 B   ALTER TABLE ONLY zipper.tape_coil DROP CONSTRAINT tape_coil_pkey;
       zipper            postgres    false    300                        2606    18666 .   tape_coil_production tape_coil_production_pkey 
   CONSTRAINT     n   ALTER TABLE ONLY zipper.tape_coil_production
    ADD CONSTRAINT tape_coil_production_pkey PRIMARY KEY (uuid);
 X   ALTER TABLE ONLY zipper.tape_coil_production DROP CONSTRAINT tape_coil_production_pkey;
       zipper            postgres    false    301            &           2606    65576 *   tape_coil_required tape_coil_required_pkey 
   CONSTRAINT     j   ALTER TABLE ONLY zipper.tape_coil_required
    ADD CONSTRAINT tape_coil_required_pkey PRIMARY KEY (uuid);
 T   ALTER TABLE ONLY zipper.tape_coil_required DROP CONSTRAINT tape_coil_required_pkey;
       zipper            postgres    false    304            "           2606    18668 ,   tape_coil_to_dyeing tape_coil_to_dyeing_pkey 
   CONSTRAINT     l   ALTER TABLE ONLY zipper.tape_coil_to_dyeing
    ADD CONSTRAINT tape_coil_to_dyeing_pkey PRIMARY KEY (uuid);
 V   ALTER TABLE ONLY zipper.tape_coil_to_dyeing DROP CONSTRAINT tape_coil_to_dyeing_pkey;
       zipper            postgres    false    302            $           2606    18670    tape_trx tape_to_coil_pkey 
   CONSTRAINT     Z   ALTER TABLE ONLY zipper.tape_trx
    ADD CONSTRAINT tape_to_coil_pkey PRIMARY KEY (uuid);
 D   ALTER TABLE ONLY zipper.tape_trx DROP CONSTRAINT tape_to_coil_pkey;
       zipper            postgres    false    303            H           2620    131174 :   pi_cash_entry sfg_after_commercial_pi_entry_delete_trigger    TRIGGER     �   CREATE TRIGGER sfg_after_commercial_pi_entry_delete_trigger AFTER DELETE ON commercial.pi_cash_entry FOR EACH ROW EXECUTE FUNCTION commercial.sfg_after_commercial_pi_entry_delete_function();
 W   DROP TRIGGER sfg_after_commercial_pi_entry_delete_trigger ON commercial.pi_cash_entry;
    
   commercial          postgres    false    309    374            I           2620    131173 :   pi_cash_entry sfg_after_commercial_pi_entry_insert_trigger    TRIGGER     �   CREATE TRIGGER sfg_after_commercial_pi_entry_insert_trigger AFTER INSERT ON commercial.pi_cash_entry FOR EACH ROW EXECUTE FUNCTION commercial.sfg_after_commercial_pi_entry_insert_function();
 W   DROP TRIGGER sfg_after_commercial_pi_entry_insert_trigger ON commercial.pi_cash_entry;
    
   commercial          postgres    false    309    368            J           2620    131175 :   pi_cash_entry sfg_after_commercial_pi_entry_update_trigger    TRIGGER     �   CREATE TRIGGER sfg_after_commercial_pi_entry_update_trigger AFTER UPDATE ON commercial.pi_cash_entry FOR EACH ROW EXECUTE FUNCTION commercial.sfg_after_commercial_pi_entry_update_function();
 W   DROP TRIGGER sfg_after_commercial_pi_entry_update_trigger ON commercial.pi_cash_entry;
    
   commercial          postgres    false    413    309                        2620    131155 5   challan_entry packing_list_after_challan_entry_delete    TRIGGER     �   CREATE TRIGGER packing_list_after_challan_entry_delete AFTER DELETE ON delivery.challan_entry FOR EACH ROW EXECUTE FUNCTION delivery.packing_list_after_challan_entry_delete_function();
 P   DROP TRIGGER packing_list_after_challan_entry_delete ON delivery.challan_entry;
       delivery          postgres    false    230    365                       2620    131154 5   challan_entry packing_list_after_challan_entry_insert    TRIGGER     �   CREATE TRIGGER packing_list_after_challan_entry_insert AFTER INSERT ON delivery.challan_entry FOR EACH ROW EXECUTE FUNCTION delivery.packing_list_after_challan_entry_insert_function();
 P   DROP TRIGGER packing_list_after_challan_entry_insert ON delivery.challan_entry;
       delivery          postgres    false    230    347                       2620    131156 5   challan_entry packing_list_after_challan_entry_update    TRIGGER     �   CREATE TRIGGER packing_list_after_challan_entry_update AFTER UPDATE ON delivery.challan_entry FOR EACH ROW EXECUTE FUNCTION delivery.packing_list_after_challan_entry_update_function();
 P   DROP TRIGGER packing_list_after_challan_entry_update ON delivery.challan_entry;
       delivery          postgres    false    230    392                       2620    131265 :   packing_list_entry sfg_after_challan_receive_status_delete    TRIGGER     �   CREATE TRIGGER sfg_after_challan_receive_status_delete AFTER DELETE ON delivery.packing_list_entry FOR EACH ROW EXECUTE FUNCTION delivery.sfg_after_challan_receive_status_delete_function();
 U   DROP TRIGGER sfg_after_challan_receive_status_delete ON delivery.packing_list_entry;
       delivery          postgres    false    232    340                       2620    131264 :   packing_list_entry sfg_after_challan_receive_status_insert    TRIGGER     �   CREATE TRIGGER sfg_after_challan_receive_status_insert AFTER INSERT ON delivery.packing_list_entry FOR EACH ROW EXECUTE FUNCTION delivery.sfg_after_challan_receive_status_insert_function();
 U   DROP TRIGGER sfg_after_challan_receive_status_insert ON delivery.packing_list_entry;
       delivery          postgres    false    358    232                       2620    131266 :   packing_list_entry sfg_after_challan_receive_status_update    TRIGGER     �   CREATE TRIGGER sfg_after_challan_receive_status_update AFTER UPDATE ON delivery.packing_list_entry FOR EACH ROW EXECUTE FUNCTION delivery.sfg_after_challan_receive_status_update_function();
 U   DROP TRIGGER sfg_after_challan_receive_status_update ON delivery.packing_list_entry;
       delivery          postgres    false    390    232                       2620    131149 6   packing_list_entry sfg_after_packing_list_entry_delete    TRIGGER     �   CREATE TRIGGER sfg_after_packing_list_entry_delete AFTER DELETE ON delivery.packing_list_entry FOR EACH ROW EXECUTE FUNCTION delivery.sfg_after_packing_list_entry_delete_function();
 Q   DROP TRIGGER sfg_after_packing_list_entry_delete ON delivery.packing_list_entry;
       delivery          postgres    false    404    232                       2620    131148 6   packing_list_entry sfg_after_packing_list_entry_insert    TRIGGER     �   CREATE TRIGGER sfg_after_packing_list_entry_insert AFTER INSERT ON delivery.packing_list_entry FOR EACH ROW EXECUTE FUNCTION delivery.sfg_after_packing_list_entry_insert_function();
 Q   DROP TRIGGER sfg_after_packing_list_entry_insert ON delivery.packing_list_entry;
       delivery          postgres    false    371    232                       2620    131150 6   packing_list_entry sfg_after_packing_list_entry_update    TRIGGER     �   CREATE TRIGGER sfg_after_packing_list_entry_update AFTER UPDATE ON delivery.packing_list_entry FOR EACH ROW EXECUTE FUNCTION delivery.sfg_after_packing_list_entry_update_function();
 Q   DROP TRIGGER sfg_after_packing_list_entry_update ON delivery.packing_list_entry;
       delivery          postgres    false    232    361            	           2620    18674 .   info material_stock_after_material_info_delete    TRIGGER     �   CREATE TRIGGER material_stock_after_material_info_delete AFTER DELETE ON material.info FOR EACH ROW EXECUTE FUNCTION material.material_stock_after_material_info_delete();
 I   DROP TRIGGER material_stock_after_material_info_delete ON material.info;
       material          postgres    false    247    334            
           2620    18675 .   info material_stock_after_material_info_insert    TRIGGER     �   CREATE TRIGGER material_stock_after_material_info_insert AFTER INSERT ON material.info FOR EACH ROW EXECUTE FUNCTION material.material_stock_after_material_info_insert();
 I   DROP TRIGGER material_stock_after_material_info_insert ON material.info;
       material          postgres    false    379    247                       2620    18676 ,   trx material_stock_after_material_trx_delete    TRIGGER     �   CREATE TRIGGER material_stock_after_material_trx_delete AFTER DELETE ON material.trx FOR EACH ROW EXECUTE FUNCTION material.material_stock_after_material_trx_delete();
 G   DROP TRIGGER material_stock_after_material_trx_delete ON material.trx;
       material          postgres    false    356    251                       2620    18677 ,   trx material_stock_after_material_trx_insert    TRIGGER     �   CREATE TRIGGER material_stock_after_material_trx_insert AFTER INSERT ON material.trx FOR EACH ROW EXECUTE FUNCTION material.material_stock_after_material_trx_insert();
 G   DROP TRIGGER material_stock_after_material_trx_insert ON material.trx;
       material          postgres    false    346    251                       2620    18678 ,   trx material_stock_after_material_trx_update    TRIGGER     �   CREATE TRIGGER material_stock_after_material_trx_update AFTER UPDATE ON material.trx FOR EACH ROW EXECUTE FUNCTION material.material_stock_after_material_trx_update();
 G   DROP TRIGGER material_stock_after_material_trx_update ON material.trx;
       material          postgres    false    251    399                       2620    18679 .   used material_stock_after_material_used_delete    TRIGGER     �   CREATE TRIGGER material_stock_after_material_used_delete AFTER DELETE ON material.used FOR EACH ROW EXECUTE FUNCTION material.material_stock_after_material_used_delete();
 I   DROP TRIGGER material_stock_after_material_used_delete ON material.used;
       material          postgres    false    351    253                       2620    18680 .   used material_stock_after_material_used_insert    TRIGGER     �   CREATE TRIGGER material_stock_after_material_used_insert AFTER INSERT ON material.used FOR EACH ROW EXECUTE FUNCTION material.material_stock_after_material_used_insert();
 I   DROP TRIGGER material_stock_after_material_used_insert ON material.used;
       material          postgres    false    363    253                       2620    18681 .   used material_stock_after_material_used_update    TRIGGER     �   CREATE TRIGGER material_stock_after_material_used_update AFTER UPDATE ON material.used FOR EACH ROW EXECUTE FUNCTION material.material_stock_after_material_used_update();
 I   DROP TRIGGER material_stock_after_material_used_update ON material.used;
       material          postgres    false    344    253                       2620    18682 9   stock_to_sfg material_stock_sfg_after_stock_to_sfg_delete    TRIGGER     �   CREATE TRIGGER material_stock_sfg_after_stock_to_sfg_delete AFTER DELETE ON material.stock_to_sfg FOR EACH ROW EXECUTE FUNCTION material.material_stock_sfg_after_stock_to_sfg_delete();
 T   DROP TRIGGER material_stock_sfg_after_stock_to_sfg_delete ON material.stock_to_sfg;
       material          postgres    false    325    250                       2620    18683 9   stock_to_sfg material_stock_sfg_after_stock_to_sfg_insert    TRIGGER     �   CREATE TRIGGER material_stock_sfg_after_stock_to_sfg_insert AFTER INSERT ON material.stock_to_sfg FOR EACH ROW EXECUTE FUNCTION material.material_stock_sfg_after_stock_to_sfg_insert();
 T   DROP TRIGGER material_stock_sfg_after_stock_to_sfg_insert ON material.stock_to_sfg;
       material          postgres    false    370    250                       2620    18684 9   stock_to_sfg material_stock_sfg_after_stock_to_sfg_update    TRIGGER     �   CREATE TRIGGER material_stock_sfg_after_stock_to_sfg_update AFTER UPDATE ON material.stock_to_sfg FOR EACH ROW EXECUTE FUNCTION material.material_stock_sfg_after_stock_to_sfg_update();
 T   DROP TRIGGER material_stock_sfg_after_stock_to_sfg_update ON material.stock_to_sfg;
       material          postgres    false    250    395                       2620    18685 0   entry material_stock_after_purchase_entry_delete    TRIGGER     �   CREATE TRIGGER material_stock_after_purchase_entry_delete AFTER DELETE ON purchase.entry FOR EACH ROW EXECUTE FUNCTION material.material_stock_after_purchase_entry_delete();
 K   DROP TRIGGER material_stock_after_purchase_entry_delete ON purchase.entry;
       purchase          postgres    false    263    352                       2620    18686 0   entry material_stock_after_purchase_entry_insert    TRIGGER     �   CREATE TRIGGER material_stock_after_purchase_entry_insert AFTER INSERT ON purchase.entry FOR EACH ROW EXECUTE FUNCTION material.material_stock_after_purchase_entry_insert();
 K   DROP TRIGGER material_stock_after_purchase_entry_insert ON purchase.entry;
       purchase          postgres    false    263    396                       2620    18687 0   entry material_stock_after_purchase_entry_update    TRIGGER     �   CREATE TRIGGER material_stock_after_purchase_entry_update AFTER UPDATE ON purchase.entry FOR EACH ROW EXECUTE FUNCTION material.material_stock_after_purchase_entry_update();
 K   DROP TRIGGER material_stock_after_purchase_entry_update ON purchase.entry;
       purchase          postgres    false    263    416            E           2620    81962 W   die_casting_to_assembly_stock assembly_stock_after_die_casting_to_assembly_stock_delete    TRIGGER     �   CREATE TRIGGER assembly_stock_after_die_casting_to_assembly_stock_delete AFTER DELETE ON slider.die_casting_to_assembly_stock FOR EACH ROW EXECUTE FUNCTION slider.assembly_stock_after_die_casting_to_assembly_stock_delete_funct();
 p   DROP TRIGGER assembly_stock_after_die_casting_to_assembly_stock_delete ON slider.die_casting_to_assembly_stock;
       slider          postgres    false    406    307            F           2620    81960 W   die_casting_to_assembly_stock assembly_stock_after_die_casting_to_assembly_stock_insert    TRIGGER     �   CREATE TRIGGER assembly_stock_after_die_casting_to_assembly_stock_insert AFTER INSERT ON slider.die_casting_to_assembly_stock FOR EACH ROW EXECUTE FUNCTION slider.assembly_stock_after_die_casting_to_assembly_stock_insert_funct();
 p   DROP TRIGGER assembly_stock_after_die_casting_to_assembly_stock_insert ON slider.die_casting_to_assembly_stock;
       slider          postgres    false    407    307            G           2620    81961 W   die_casting_to_assembly_stock assembly_stock_after_die_casting_to_assembly_stock_update    TRIGGER     �   CREATE TRIGGER assembly_stock_after_die_casting_to_assembly_stock_update AFTER UPDATE ON slider.die_casting_to_assembly_stock FOR EACH ROW EXECUTE FUNCTION slider.assembly_stock_after_die_casting_to_assembly_stock_update_funct();
 p   DROP TRIGGER assembly_stock_after_die_casting_to_assembly_stock_update ON slider.die_casting_to_assembly_stock;
       slider          postgres    false    401    307                       2620    18688 M   die_casting_production slider_die_casting_after_die_casting_production_delete    TRIGGER     �   CREATE TRIGGER slider_die_casting_after_die_casting_production_delete AFTER DELETE ON slider.die_casting_production FOR EACH ROW EXECUTE FUNCTION slider.slider_die_casting_after_die_casting_production_delete();
 f   DROP TRIGGER slider_die_casting_after_die_casting_production_delete ON slider.die_casting_production;
       slider          postgres    false    267    364                       2620    18689 M   die_casting_production slider_die_casting_after_die_casting_production_insert    TRIGGER     �   CREATE TRIGGER slider_die_casting_after_die_casting_production_insert AFTER INSERT ON slider.die_casting_production FOR EACH ROW EXECUTE FUNCTION slider.slider_die_casting_after_die_casting_production_insert();
 f   DROP TRIGGER slider_die_casting_after_die_casting_production_insert ON slider.die_casting_production;
       slider          postgres    false    267    378                       2620    18690 M   die_casting_production slider_die_casting_after_die_casting_production_update    TRIGGER     �   CREATE TRIGGER slider_die_casting_after_die_casting_production_update AFTER UPDATE ON slider.die_casting_production FOR EACH ROW EXECUTE FUNCTION slider.slider_die_casting_after_die_casting_production_update();
 f   DROP TRIGGER slider_die_casting_after_die_casting_production_update ON slider.die_casting_production;
       slider          postgres    false    267    343            &           2620    18691 C   trx_against_stock slider_die_casting_after_trx_against_stock_delete    TRIGGER     �   CREATE TRIGGER slider_die_casting_after_trx_against_stock_delete AFTER DELETE ON slider.trx_against_stock FOR EACH ROW EXECUTE FUNCTION slider.slider_die_casting_after_trx_against_stock_delete();
 \   DROP TRIGGER slider_die_casting_after_trx_against_stock_delete ON slider.trx_against_stock;
       slider          postgres    false    272    342            '           2620    18692 C   trx_against_stock slider_die_casting_after_trx_against_stock_insert    TRIGGER     �   CREATE TRIGGER slider_die_casting_after_trx_against_stock_insert AFTER INSERT ON slider.trx_against_stock FOR EACH ROW EXECUTE FUNCTION slider.slider_die_casting_after_trx_against_stock_insert();
 \   DROP TRIGGER slider_die_casting_after_trx_against_stock_insert ON slider.trx_against_stock;
       slider          postgres    false    272    412            (           2620    18693 C   trx_against_stock slider_die_casting_after_trx_against_stock_update    TRIGGER     �   CREATE TRIGGER slider_die_casting_after_trx_against_stock_update AFTER UPDATE ON slider.trx_against_stock FOR EACH ROW EXECUTE FUNCTION slider.slider_die_casting_after_trx_against_stock_update();
 \   DROP TRIGGER slider_die_casting_after_trx_against_stock_update ON slider.trx_against_stock;
       slider          postgres    false    272    375                       2620    18694 C   coloring_transaction slider_stock_after_coloring_transaction_delete    TRIGGER     �   CREATE TRIGGER slider_stock_after_coloring_transaction_delete AFTER DELETE ON slider.coloring_transaction FOR EACH ROW EXECUTE FUNCTION slider.slider_stock_after_coloring_transaction_delete();
 \   DROP TRIGGER slider_stock_after_coloring_transaction_delete ON slider.coloring_transaction;
       slider          postgres    false    332    265                       2620    18695 C   coloring_transaction slider_stock_after_coloring_transaction_insert    TRIGGER     �   CREATE TRIGGER slider_stock_after_coloring_transaction_insert AFTER INSERT ON slider.coloring_transaction FOR EACH ROW EXECUTE FUNCTION slider.slider_stock_after_coloring_transaction_insert();
 \   DROP TRIGGER slider_stock_after_coloring_transaction_insert ON slider.coloring_transaction;
       slider          postgres    false    345    265                       2620    18696 C   coloring_transaction slider_stock_after_coloring_transaction_update    TRIGGER     �   CREATE TRIGGER slider_stock_after_coloring_transaction_update AFTER UPDATE ON slider.coloring_transaction FOR EACH ROW EXECUTE FUNCTION slider.slider_stock_after_coloring_transaction_update();
 \   DROP TRIGGER slider_stock_after_coloring_transaction_update ON slider.coloring_transaction;
       slider          postgres    false    265    402                       2620    18697 I   die_casting_transaction slider_stock_after_die_casting_transaction_delete    TRIGGER     �   CREATE TRIGGER slider_stock_after_die_casting_transaction_delete AFTER DELETE ON slider.die_casting_transaction FOR EACH ROW EXECUTE FUNCTION slider.slider_stock_after_die_casting_transaction_delete();
 b   DROP TRIGGER slider_stock_after_die_casting_transaction_delete ON slider.die_casting_transaction;
       slider          postgres    false    320    268                       2620    18698 I   die_casting_transaction slider_stock_after_die_casting_transaction_insert    TRIGGER     �   CREATE TRIGGER slider_stock_after_die_casting_transaction_insert AFTER INSERT ON slider.die_casting_transaction FOR EACH ROW EXECUTE FUNCTION slider.slider_stock_after_die_casting_transaction_insert();
 b   DROP TRIGGER slider_stock_after_die_casting_transaction_insert ON slider.die_casting_transaction;
       slider          postgres    false    268    324                       2620    18699 I   die_casting_transaction slider_stock_after_die_casting_transaction_update    TRIGGER     �   CREATE TRIGGER slider_stock_after_die_casting_transaction_update AFTER UPDATE ON slider.die_casting_transaction FOR EACH ROW EXECUTE FUNCTION slider.slider_stock_after_die_casting_transaction_update();
 b   DROP TRIGGER slider_stock_after_die_casting_transaction_update ON slider.die_casting_transaction;
       slider          postgres    false    362    268                        2620    18700 6   production slider_stock_after_slider_production_delete    TRIGGER     �   CREATE TRIGGER slider_stock_after_slider_production_delete AFTER DELETE ON slider.production FOR EACH ROW EXECUTE FUNCTION slider.slider_stock_after_slider_production_delete();
 O   DROP TRIGGER slider_stock_after_slider_production_delete ON slider.production;
       slider          postgres    false    269    323            !           2620    18701 6   production slider_stock_after_slider_production_insert    TRIGGER     �   CREATE TRIGGER slider_stock_after_slider_production_insert AFTER INSERT ON slider.production FOR EACH ROW EXECUTE FUNCTION slider.slider_stock_after_slider_production_insert();
 O   DROP TRIGGER slider_stock_after_slider_production_insert ON slider.production;
       slider          postgres    false    408    269            "           2620    18702 6   production slider_stock_after_slider_production_update    TRIGGER     �   CREATE TRIGGER slider_stock_after_slider_production_update AFTER UPDATE ON slider.production FOR EACH ROW EXECUTE FUNCTION slider.slider_stock_after_slider_production_update();
 O   DROP TRIGGER slider_stock_after_slider_production_update ON slider.production;
       slider          postgres    false    269    384            #           2620    18703 1   transaction slider_stock_after_transaction_delete    TRIGGER     �   CREATE TRIGGER slider_stock_after_transaction_delete AFTER DELETE ON slider.transaction FOR EACH ROW EXECUTE FUNCTION slider.slider_stock_after_transaction_delete();
 J   DROP TRIGGER slider_stock_after_transaction_delete ON slider.transaction;
       slider          postgres    false    271    327            $           2620    18704 1   transaction slider_stock_after_transaction_insert    TRIGGER     �   CREATE TRIGGER slider_stock_after_transaction_insert AFTER INSERT ON slider.transaction FOR EACH ROW EXECUTE FUNCTION slider.slider_stock_after_transaction_insert();
 J   DROP TRIGGER slider_stock_after_transaction_insert ON slider.transaction;
       slider          postgres    false    405    271            %           2620    18705 1   transaction slider_stock_after_transaction_update    TRIGGER     �   CREATE TRIGGER slider_stock_after_transaction_update AFTER UPDATE ON slider.transaction FOR EACH ROW EXECUTE FUNCTION slider.slider_stock_after_transaction_update();
 J   DROP TRIGGER slider_stock_after_transaction_update ON slider.transaction;
       slider          postgres    false    271    329            )           2620    131172 7   batch order_entry_after_batch_is_drying_update_function    TRIGGER     �   CREATE TRIGGER order_entry_after_batch_is_drying_update_function AFTER UPDATE ON thread.batch FOR EACH ROW EXECUTE FUNCTION thread.order_entry_after_batch_is_drying_update();
 P   DROP TRIGGER order_entry_after_batch_is_drying_update_function ON thread.batch;
       thread          postgres    false    274    381            *           2620    131170 7   batch order_entry_after_batch_is_dyeing_update_function    TRIGGER     �   CREATE TRIGGER order_entry_after_batch_is_dyeing_update_function AFTER UPDATE OF is_drying_complete ON thread.batch FOR EACH ROW EXECUTE FUNCTION thread.order_entry_after_batch_is_dyeing_update();
 P   DROP TRIGGER order_entry_after_batch_is_dyeing_update_function ON thread.batch;
       thread          postgres    false    388    274    274            N           2620    131275 M   batch_entry_production thread_batch_entry_after_batch_entry_production_delete    TRIGGER     �   CREATE TRIGGER thread_batch_entry_after_batch_entry_production_delete AFTER DELETE ON thread.batch_entry_production FOR EACH ROW EXECUTE FUNCTION public.thread_batch_entry_after_batch_entry_production_delete_funct();
 f   DROP TRIGGER thread_batch_entry_after_batch_entry_production_delete ON thread.batch_entry_production;
       thread          postgres    false    387    314            O           2620    131274 M   batch_entry_production thread_batch_entry_after_batch_entry_production_insert    TRIGGER     �   CREATE TRIGGER thread_batch_entry_after_batch_entry_production_insert AFTER INSERT ON thread.batch_entry_production FOR EACH ROW EXECUTE FUNCTION public.thread_batch_entry_after_batch_entry_production_insert_funct();
 f   DROP TRIGGER thread_batch_entry_after_batch_entry_production_insert ON thread.batch_entry_production;
       thread          postgres    false    391    314            P           2620    131276 M   batch_entry_production thread_batch_entry_after_batch_entry_production_update    TRIGGER     �   CREATE TRIGGER thread_batch_entry_after_batch_entry_production_update AFTER UPDATE ON thread.batch_entry_production FOR EACH ROW EXECUTE FUNCTION public.thread_batch_entry_after_batch_entry_production_update_funct();
 f   DROP TRIGGER thread_batch_entry_after_batch_entry_production_update ON thread.batch_entry_production;
       thread          postgres    false    333    314            Q           2620    131280 H   batch_entry_trx thread_batch_entry_and_order_entry_after_batch_entry_trx    TRIGGER     �   CREATE TRIGGER thread_batch_entry_and_order_entry_after_batch_entry_trx AFTER INSERT ON thread.batch_entry_trx FOR EACH ROW EXECUTE FUNCTION public.thread_batch_entry_and_order_entry_after_batch_entry_trx_funct();
 a   DROP TRIGGER thread_batch_entry_and_order_entry_after_batch_entry_trx ON thread.batch_entry_trx;
       thread          postgres    false    315    398            R           2620    131281 O   batch_entry_trx thread_batch_entry_and_order_entry_after_batch_entry_trx_delete    TRIGGER     �   CREATE TRIGGER thread_batch_entry_and_order_entry_after_batch_entry_trx_delete AFTER DELETE ON thread.batch_entry_trx FOR EACH ROW EXECUTE FUNCTION public.thread_batch_entry_and_order_entry_after_batch_entry_trx_delete();
 h   DROP TRIGGER thread_batch_entry_and_order_entry_after_batch_entry_trx_delete ON thread.batch_entry_trx;
       thread          postgres    false    373    315            S           2620    131282 O   batch_entry_trx thread_batch_entry_and_order_entry_after_batch_entry_trx_update    TRIGGER     �   CREATE TRIGGER thread_batch_entry_and_order_entry_after_batch_entry_trx_update AFTER UPDATE ON thread.batch_entry_trx FOR EACH ROW EXECUTE FUNCTION public.thread_batch_entry_and_order_entry_after_batch_entry_trx_update();
 h   DROP TRIGGER thread_batch_entry_and_order_entry_after_batch_entry_trx_update ON thread.batch_entry_trx;
       thread          postgres    false    315    389            .           2620    18706 R   dyed_tape_transaction order_description_after_dyed_tape_transaction_delete_trigger    TRIGGER     �   CREATE TRIGGER order_description_after_dyed_tape_transaction_delete_trigger AFTER DELETE ON zipper.dyed_tape_transaction FOR EACH ROW EXECUTE FUNCTION zipper.order_description_after_dyed_tape_transaction_delete();
 k   DROP TRIGGER order_description_after_dyed_tape_transaction_delete_trigger ON zipper.dyed_tape_transaction;
       zipper          postgres    false    353    286            /           2620    18707 R   dyed_tape_transaction order_description_after_dyed_tape_transaction_insert_trigger    TRIGGER     �   CREATE TRIGGER order_description_after_dyed_tape_transaction_insert_trigger AFTER INSERT ON zipper.dyed_tape_transaction FOR EACH ROW EXECUTE FUNCTION zipper.order_description_after_dyed_tape_transaction_insert();
 k   DROP TRIGGER order_description_after_dyed_tape_transaction_insert_trigger ON zipper.dyed_tape_transaction;
       zipper          postgres    false    286    376            0           2620    18708 R   dyed_tape_transaction order_description_after_dyed_tape_transaction_update_trigger    TRIGGER     �   CREATE TRIGGER order_description_after_dyed_tape_transaction_update_trigger AFTER UPDATE ON zipper.dyed_tape_transaction FOR EACH ROW EXECUTE FUNCTION zipper.order_description_after_dyed_tape_transaction_update();
 k   DROP TRIGGER order_description_after_dyed_tape_transaction_update_trigger ON zipper.dyed_tape_transaction;
       zipper          postgres    false    286    411            4           2620    18709 (   order_entry sfg_after_order_entry_delete    TRIGGER     �   CREATE TRIGGER sfg_after_order_entry_delete AFTER DELETE ON zipper.order_entry FOR EACH ROW EXECUTE FUNCTION zipper.sfg_after_order_entry_delete();
 A   DROP TRIGGER sfg_after_order_entry_delete ON zipper.order_entry;
       zipper          postgres    false    292    360            5           2620    18710 (   order_entry sfg_after_order_entry_insert    TRIGGER     �   CREATE TRIGGER sfg_after_order_entry_insert AFTER INSERT ON zipper.order_entry FOR EACH ROW EXECUTE FUNCTION zipper.sfg_after_order_entry_insert();
 A   DROP TRIGGER sfg_after_order_entry_insert ON zipper.order_entry;
       zipper          postgres    false    330    292            6           2620    18711 6   sfg_production sfg_after_sfg_production_delete_trigger    TRIGGER     �   CREATE TRIGGER sfg_after_sfg_production_delete_trigger AFTER DELETE ON zipper.sfg_production FOR EACH ROW EXECUTE FUNCTION zipper.sfg_after_sfg_production_delete_function();
 O   DROP TRIGGER sfg_after_sfg_production_delete_trigger ON zipper.sfg_production;
       zipper          postgres    false    348    298            7           2620    18712 6   sfg_production sfg_after_sfg_production_insert_trigger    TRIGGER     �   CREATE TRIGGER sfg_after_sfg_production_insert_trigger AFTER INSERT ON zipper.sfg_production FOR EACH ROW EXECUTE FUNCTION zipper.sfg_after_sfg_production_insert_function();
 O   DROP TRIGGER sfg_after_sfg_production_insert_trigger ON zipper.sfg_production;
       zipper          postgres    false    298    409            8           2620    18713 6   sfg_production sfg_after_sfg_production_update_trigger    TRIGGER     �   CREATE TRIGGER sfg_after_sfg_production_update_trigger AFTER UPDATE ON zipper.sfg_production FOR EACH ROW EXECUTE FUNCTION zipper.sfg_after_sfg_production_update_function();
 O   DROP TRIGGER sfg_after_sfg_production_update_trigger ON zipper.sfg_production;
       zipper          postgres    false    335    298            9           2620    106501 8   sfg_transaction sfg_after_sfg_transaction_delete_trigger    TRIGGER     �   CREATE TRIGGER sfg_after_sfg_transaction_delete_trigger AFTER DELETE ON zipper.sfg_transaction FOR EACH ROW EXECUTE FUNCTION zipper.sfg_after_sfg_transaction_delete_function();
 Q   DROP TRIGGER sfg_after_sfg_transaction_delete_trigger ON zipper.sfg_transaction;
       zipper          postgres    false    299    382            :           2620    32768 8   sfg_transaction sfg_after_sfg_transaction_insert_trigger    TRIGGER     �   CREATE TRIGGER sfg_after_sfg_transaction_insert_trigger AFTER INSERT ON zipper.sfg_transaction FOR EACH ROW EXECUTE FUNCTION zipper.sfg_after_sfg_transaction_insert_function();
 Q   DROP TRIGGER sfg_after_sfg_transaction_insert_trigger ON zipper.sfg_transaction;
       zipper          postgres    false    322    299            ;           2620    106502 8   sfg_transaction sfg_after_sfg_transaction_update_trigger    TRIGGER     �   CREATE TRIGGER sfg_after_sfg_transaction_update_trigger AFTER UPDATE ON zipper.sfg_transaction FOR EACH ROW EXECUTE FUNCTION zipper.sfg_after_sfg_transaction_update_function();
 Q   DROP TRIGGER sfg_after_sfg_transaction_update_trigger ON zipper.sfg_transaction;
       zipper          postgres    false    410    299            1           2620    18717 `   material_trx_against_order_description stock_after_material_trx_against_order_description_delete    TRIGGER     �   CREATE TRIGGER stock_after_material_trx_against_order_description_delete AFTER DELETE ON zipper.material_trx_against_order_description FOR EACH ROW EXECUTE FUNCTION zipper.stock_after_material_trx_against_order_description_delete_funct();
 y   DROP TRIGGER stock_after_material_trx_against_order_description_delete ON zipper.material_trx_against_order_description;
       zipper          postgres    false    290    359            2           2620    18718 `   material_trx_against_order_description stock_after_material_trx_against_order_description_insert    TRIGGER     �   CREATE TRIGGER stock_after_material_trx_against_order_description_insert AFTER INSERT ON zipper.material_trx_against_order_description FOR EACH ROW EXECUTE FUNCTION zipper.stock_after_material_trx_against_order_description_insert_funct();
 y   DROP TRIGGER stock_after_material_trx_against_order_description_insert ON zipper.material_trx_against_order_description;
       zipper          postgres    false    377    290            3           2620    18719 `   material_trx_against_order_description stock_after_material_trx_against_order_description_update    TRIGGER     �   CREATE TRIGGER stock_after_material_trx_against_order_description_update AFTER UPDATE ON zipper.material_trx_against_order_description FOR EACH ROW EXECUTE FUNCTION zipper.stock_after_material_trx_against_order_description_update_funct();
 y   DROP TRIGGER stock_after_material_trx_against_order_description_update ON zipper.material_trx_against_order_description;
       zipper          postgres    false    403    290            <           2620    18720 9   tape_coil_production tape_coil_after_tape_coil_production    TRIGGER     �   CREATE TRIGGER tape_coil_after_tape_coil_production AFTER INSERT ON zipper.tape_coil_production FOR EACH ROW EXECUTE FUNCTION zipper.tape_coil_after_tape_coil_production();
 R   DROP TRIGGER tape_coil_after_tape_coil_production ON zipper.tape_coil_production;
       zipper          postgres    false    301    393            =           2620    18721 @   tape_coil_production tape_coil_after_tape_coil_production_delete    TRIGGER     �   CREATE TRIGGER tape_coil_after_tape_coil_production_delete AFTER DELETE ON zipper.tape_coil_production FOR EACH ROW EXECUTE FUNCTION zipper.tape_coil_after_tape_coil_production_delete();
 Y   DROP TRIGGER tape_coil_after_tape_coil_production_delete ON zipper.tape_coil_production;
       zipper          postgres    false    326    301            >           2620    18722 @   tape_coil_production tape_coil_after_tape_coil_production_update    TRIGGER     �   CREATE TRIGGER tape_coil_after_tape_coil_production_update AFTER UPDATE ON zipper.tape_coil_production FOR EACH ROW EXECUTE FUNCTION zipper.tape_coil_after_tape_coil_production_update();
 Y   DROP TRIGGER tape_coil_after_tape_coil_production_update ON zipper.tape_coil_production;
       zipper          postgres    false    369    301            B           2620    81967 .   tape_trx tape_coil_after_tape_trx_after_delete    TRIGGER     �   CREATE TRIGGER tape_coil_after_tape_trx_after_delete AFTER DELETE ON zipper.tape_trx FOR EACH ROW EXECUTE FUNCTION zipper.tape_coil_after_tape_trx_delete();
 G   DROP TRIGGER tape_coil_after_tape_trx_after_delete ON zipper.tape_trx;
       zipper          postgres    false    303    354            C           2620    81966 .   tape_trx tape_coil_after_tape_trx_after_insert    TRIGGER     �   CREATE TRIGGER tape_coil_after_tape_trx_after_insert AFTER INSERT ON zipper.tape_trx FOR EACH ROW EXECUTE FUNCTION zipper.tape_coil_after_tape_trx_insert();
 G   DROP TRIGGER tape_coil_after_tape_trx_after_insert ON zipper.tape_trx;
       zipper          postgres    false    397    303            D           2620    81968 .   tape_trx tape_coil_after_tape_trx_after_update    TRIGGER     �   CREATE TRIGGER tape_coil_after_tape_trx_after_update AFTER UPDATE ON zipper.tape_trx FOR EACH ROW EXECUTE FUNCTION zipper.tape_coil_after_tape_trx_update();
 G   DROP TRIGGER tape_coil_after_tape_trx_after_update ON zipper.tape_trx;
       zipper          postgres    false    303    337            K           2620    131116 `   dyed_tape_transaction_from_stock tape_coil_and_order_description_after_dyed_tape_transaction_del    TRIGGER     �   CREATE TRIGGER tape_coil_and_order_description_after_dyed_tape_transaction_del AFTER DELETE ON zipper.dyed_tape_transaction_from_stock FOR EACH ROW EXECUTE FUNCTION zipper.tape_coil_and_order_description_after_dyed_tape_transaction_del();
 y   DROP TRIGGER tape_coil_and_order_description_after_dyed_tape_transaction_del ON zipper.dyed_tape_transaction_from_stock;
       zipper          postgres    false    350    313            L           2620    131114 `   dyed_tape_transaction_from_stock tape_coil_and_order_description_after_dyed_tape_transaction_ins    TRIGGER     �   CREATE TRIGGER tape_coil_and_order_description_after_dyed_tape_transaction_ins AFTER INSERT ON zipper.dyed_tape_transaction_from_stock FOR EACH ROW EXECUTE FUNCTION zipper.tape_coil_and_order_description_after_dyed_tape_transaction_ins();
 y   DROP TRIGGER tape_coil_and_order_description_after_dyed_tape_transaction_ins ON zipper.dyed_tape_transaction_from_stock;
       zipper          postgres    false    385    313            M           2620    131115 `   dyed_tape_transaction_from_stock tape_coil_and_order_description_after_dyed_tape_transaction_upd    TRIGGER     �   CREATE TRIGGER tape_coil_and_order_description_after_dyed_tape_transaction_upd AFTER UPDATE ON zipper.dyed_tape_transaction_from_stock FOR EACH ROW EXECUTE FUNCTION zipper.tape_coil_and_order_description_after_dyed_tape_transaction_upd();
 y   DROP TRIGGER tape_coil_and_order_description_after_dyed_tape_transaction_upd ON zipper.dyed_tape_transaction_from_stock;
       zipper          postgres    false    336    313            ?           2620    24580 4   tape_coil_to_dyeing tape_coil_to_dyeing_after_delete    TRIGGER     �   CREATE TRIGGER tape_coil_to_dyeing_after_delete AFTER DELETE ON zipper.tape_coil_to_dyeing FOR EACH ROW EXECUTE FUNCTION zipper.order_description_after_tape_coil_to_dyeing_delete();
 M   DROP TRIGGER tape_coil_to_dyeing_after_delete ON zipper.tape_coil_to_dyeing;
       zipper          postgres    false    400    302            @           2620    24579 4   tape_coil_to_dyeing tape_coil_to_dyeing_after_insert    TRIGGER     �   CREATE TRIGGER tape_coil_to_dyeing_after_insert AFTER INSERT ON zipper.tape_coil_to_dyeing FOR EACH ROW EXECUTE FUNCTION zipper.order_description_after_tape_coil_to_dyeing_insert();
 M   DROP TRIGGER tape_coil_to_dyeing_after_insert ON zipper.tape_coil_to_dyeing;
       zipper          postgres    false    338    302            A           2620    24581 4   tape_coil_to_dyeing tape_coil_to_dyeing_after_update    TRIGGER     �   CREATE TRIGGER tape_coil_to_dyeing_after_update AFTER UPDATE ON zipper.tape_coil_to_dyeing FOR EACH ROW EXECUTE FUNCTION zipper.order_description_after_tape_coil_to_dyeing_update();
 M   DROP TRIGGER tape_coil_to_dyeing_after_update ON zipper.tape_coil_to_dyeing;
       zipper          postgres    false    302    328            +           2620    98306 A   batch_production zipper_batch_entry_after_batch_production_delete    TRIGGER     �   CREATE TRIGGER zipper_batch_entry_after_batch_production_delete AFTER DELETE ON zipper.batch_production FOR EACH ROW EXECUTE FUNCTION public.zipper_batch_entry_after_batch_production_delete();
 Z   DROP TRIGGER zipper_batch_entry_after_batch_production_delete ON zipper.batch_production;
       zipper          postgres    false    341    285            ,           2620    98304 A   batch_production zipper_batch_entry_after_batch_production_insert    TRIGGER     �   CREATE TRIGGER zipper_batch_entry_after_batch_production_insert AFTER INSERT ON zipper.batch_production FOR EACH ROW EXECUTE FUNCTION public.zipper_batch_entry_after_batch_production_insert();
 Z   DROP TRIGGER zipper_batch_entry_after_batch_production_insert ON zipper.batch_production;
       zipper          postgres    false    366    285            -           2620    98305 A   batch_production zipper_batch_entry_after_batch_production_update    TRIGGER     �   CREATE TRIGGER zipper_batch_entry_after_batch_production_update AFTER UPDATE ON zipper.batch_production FOR EACH ROW EXECUTE FUNCTION public.zipper_batch_entry_after_batch_production_update();
 Z   DROP TRIGGER zipper_batch_entry_after_batch_production_update ON zipper.batch_production;
       zipper          postgres    false    285    321            ;           2606    18726 "   bank bank_created_by_users_uuid_fk    FK CONSTRAINT     �   ALTER TABLE ONLY commercial.bank
    ADD CONSTRAINT bank_created_by_users_uuid_fk FOREIGN KEY (created_by) REFERENCES hr.users(uuid);
 P   ALTER TABLE ONLY commercial.bank DROP CONSTRAINT bank_created_by_users_uuid_fk;
    
   commercial          postgres    false    5290    225    238            <           2606    18731    lc lc_created_by_users_uuid_fk    FK CONSTRAINT     �   ALTER TABLE ONLY commercial.lc
    ADD CONSTRAINT lc_created_by_users_uuid_fk FOREIGN KEY (created_by) REFERENCES hr.users(uuid);
 L   ALTER TABLE ONLY commercial.lc DROP CONSTRAINT lc_created_by_users_uuid_fk;
    
   commercial          postgres    false    5290    227    238            =           2606    18736    lc lc_party_uuid_party_uuid_fk    FK CONSTRAINT     �   ALTER TABLE ONLY commercial.lc
    ADD CONSTRAINT lc_party_uuid_party_uuid_fk FOREIGN KEY (party_uuid) REFERENCES public.party(uuid);
 L   ALTER TABLE ONLY commercial.lc DROP CONSTRAINT lc_party_uuid_party_uuid_fk;
    
   commercial          postgres    false    227    258    5334            �           2606    82034 &   pi_cash pi_cash_bank_uuid_bank_uuid_fk    FK CONSTRAINT     �   ALTER TABLE ONLY commercial.pi_cash
    ADD CONSTRAINT pi_cash_bank_uuid_bank_uuid_fk FOREIGN KEY (bank_uuid) REFERENCES commercial.bank(uuid);
 T   ALTER TABLE ONLY commercial.pi_cash DROP CONSTRAINT pi_cash_bank_uuid_bank_uuid_fk;
    
   commercial          postgres    false    5268    308    225            �           2606    82039 (   pi_cash pi_cash_created_by_users_uuid_fk    FK CONSTRAINT     �   ALTER TABLE ONLY commercial.pi_cash
    ADD CONSTRAINT pi_cash_created_by_users_uuid_fk FOREIGN KEY (created_by) REFERENCES hr.users(uuid);
 V   ALTER TABLE ONLY commercial.pi_cash DROP CONSTRAINT pi_cash_created_by_users_uuid_fk;
    
   commercial          postgres    false    5290    238    308            �           2606    82044 8   pi_cash_entry pi_cash_entry_pi_cash_uuid_pi_cash_uuid_fk    FK CONSTRAINT     �   ALTER TABLE ONLY commercial.pi_cash_entry
    ADD CONSTRAINT pi_cash_entry_pi_cash_uuid_pi_cash_uuid_fk FOREIGN KEY (pi_cash_uuid) REFERENCES commercial.pi_cash(uuid);
 f   ALTER TABLE ONLY commercial.pi_cash_entry DROP CONSTRAINT pi_cash_entry_pi_cash_uuid_pi_cash_uuid_fk;
    
   commercial          postgres    false    5422    308    309            �           2606    82049 0   pi_cash_entry pi_cash_entry_sfg_uuid_sfg_uuid_fk    FK CONSTRAINT     �   ALTER TABLE ONLY commercial.pi_cash_entry
    ADD CONSTRAINT pi_cash_entry_sfg_uuid_sfg_uuid_fk FOREIGN KEY (sfg_uuid) REFERENCES zipper.sfg(uuid);
 ^   ALTER TABLE ONLY commercial.pi_cash_entry DROP CONSTRAINT pi_cash_entry_sfg_uuid_sfg_uuid_fk;
    
   commercial          postgres    false    309    5400    297            �           2606    131179 G   pi_cash_entry pi_cash_entry_thread_order_entry_uuid_order_entry_uuid_fk    FK CONSTRAINT     �   ALTER TABLE ONLY commercial.pi_cash_entry
    ADD CONSTRAINT pi_cash_entry_thread_order_entry_uuid_order_entry_uuid_fk FOREIGN KEY (thread_order_entry_uuid) REFERENCES thread.order_entry(uuid);
 u   ALTER TABLE ONLY commercial.pi_cash_entry DROP CONSTRAINT pi_cash_entry_thread_order_entry_uuid_order_entry_uuid_fk;
    
   commercial          postgres    false    278    5370    309            �           2606    82029 ,   pi_cash pi_cash_factory_uuid_factory_uuid_fk    FK CONSTRAINT     �   ALTER TABLE ONLY commercial.pi_cash
    ADD CONSTRAINT pi_cash_factory_uuid_factory_uuid_fk FOREIGN KEY (factory_uuid) REFERENCES public.factory(uuid);
 Z   ALTER TABLE ONLY commercial.pi_cash DROP CONSTRAINT pi_cash_factory_uuid_factory_uuid_fk;
    
   commercial          postgres    false    5322    255    308            �           2606    82009 "   pi_cash pi_cash_lc_uuid_lc_uuid_fk    FK CONSTRAINT     �   ALTER TABLE ONLY commercial.pi_cash
    ADD CONSTRAINT pi_cash_lc_uuid_lc_uuid_fk FOREIGN KEY (lc_uuid) REFERENCES commercial.lc(uuid);
 P   ALTER TABLE ONLY commercial.pi_cash DROP CONSTRAINT pi_cash_lc_uuid_lc_uuid_fk;
    
   commercial          postgres    false    227    308    5270            �           2606    82014 0   pi_cash pi_cash_marketing_uuid_marketing_uuid_fk    FK CONSTRAINT     �   ALTER TABLE ONLY commercial.pi_cash
    ADD CONSTRAINT pi_cash_marketing_uuid_marketing_uuid_fk FOREIGN KEY (marketing_uuid) REFERENCES public.marketing(uuid);
 ^   ALTER TABLE ONLY commercial.pi_cash DROP CONSTRAINT pi_cash_marketing_uuid_marketing_uuid_fk;
    
   commercial          postgres    false    256    5326    308            �           2606    82024 6   pi_cash pi_cash_merchandiser_uuid_merchandiser_uuid_fk    FK CONSTRAINT     �   ALTER TABLE ONLY commercial.pi_cash
    ADD CONSTRAINT pi_cash_merchandiser_uuid_merchandiser_uuid_fk FOREIGN KEY (merchandiser_uuid) REFERENCES public.merchandiser(uuid);
 d   ALTER TABLE ONLY commercial.pi_cash DROP CONSTRAINT pi_cash_merchandiser_uuid_merchandiser_uuid_fk;
    
   commercial          postgres    false    5330    308    257            �           2606    82019 (   pi_cash pi_cash_party_uuid_party_uuid_fk    FK CONSTRAINT     �   ALTER TABLE ONLY commercial.pi_cash
    ADD CONSTRAINT pi_cash_party_uuid_party_uuid_fk FOREIGN KEY (party_uuid) REFERENCES public.party(uuid);
 V   ALTER TABLE ONLY commercial.pi_cash DROP CONSTRAINT pi_cash_party_uuid_party_uuid_fk;
    
   commercial          postgres    false    258    5334    308            >           2606    18786 '   challan challan_assign_to_users_uuid_fk    FK CONSTRAINT     �   ALTER TABLE ONLY delivery.challan
    ADD CONSTRAINT challan_assign_to_users_uuid_fk FOREIGN KEY (assign_to) REFERENCES hr.users(uuid);
 S   ALTER TABLE ONLY delivery.challan DROP CONSTRAINT challan_assign_to_users_uuid_fk;
       delivery          postgres    false    238    229    5290            ?           2606    18791 (   challan challan_created_by_users_uuid_fk    FK CONSTRAINT     �   ALTER TABLE ONLY delivery.challan
    ADD CONSTRAINT challan_created_by_users_uuid_fk FOREIGN KEY (created_by) REFERENCES hr.users(uuid);
 T   ALTER TABLE ONLY delivery.challan DROP CONSTRAINT challan_created_by_users_uuid_fk;
       delivery          postgres    false    5290    229    238            A           2606    18796 8   challan_entry challan_entry_challan_uuid_challan_uuid_fk    FK CONSTRAINT     �   ALTER TABLE ONLY delivery.challan_entry
    ADD CONSTRAINT challan_entry_challan_uuid_challan_uuid_fk FOREIGN KEY (challan_uuid) REFERENCES delivery.challan(uuid);
 d   ALTER TABLE ONLY delivery.challan_entry DROP CONSTRAINT challan_entry_challan_uuid_challan_uuid_fk;
       delivery          postgres    false    229    230    5272            B           2606    18801 B   challan_entry challan_entry_packing_list_uuid_packing_list_uuid_fk    FK CONSTRAINT     �   ALTER TABLE ONLY delivery.challan_entry
    ADD CONSTRAINT challan_entry_packing_list_uuid_packing_list_uuid_fk FOREIGN KEY (packing_list_uuid) REFERENCES delivery.packing_list(uuid);
 n   ALTER TABLE ONLY delivery.challan_entry DROP CONSTRAINT challan_entry_packing_list_uuid_packing_list_uuid_fk;
       delivery          postgres    false    5276    230    231            @           2606    131106 2   challan challan_order_info_uuid_order_info_uuid_fk    FK CONSTRAINT     �   ALTER TABLE ONLY delivery.challan
    ADD CONSTRAINT challan_order_info_uuid_order_info_uuid_fk FOREIGN KEY (order_info_uuid) REFERENCES zipper.order_info(uuid);
 ^   ALTER TABLE ONLY delivery.challan DROP CONSTRAINT challan_order_info_uuid_order_info_uuid_fk;
       delivery          postgres    false    5394    294    229            C           2606    131140 6   packing_list packing_list_challan_uuid_challan_uuid_fk    FK CONSTRAINT     �   ALTER TABLE ONLY delivery.packing_list
    ADD CONSTRAINT packing_list_challan_uuid_challan_uuid_fk FOREIGN KEY (challan_uuid) REFERENCES delivery.challan(uuid);
 b   ALTER TABLE ONLY delivery.packing_list DROP CONSTRAINT packing_list_challan_uuid_challan_uuid_fk;
       delivery          postgres    false    5272    231    229            D           2606    65652 2   packing_list packing_list_created_by_users_uuid_fk    FK CONSTRAINT     �   ALTER TABLE ONLY delivery.packing_list
    ADD CONSTRAINT packing_list_created_by_users_uuid_fk FOREIGN KEY (created_by) REFERENCES hr.users(uuid);
 ^   ALTER TABLE ONLY delivery.packing_list DROP CONSTRAINT packing_list_created_by_users_uuid_fk;
       delivery          postgres    false    5290    231    238            F           2606    18806 L   packing_list_entry packing_list_entry_packing_list_uuid_packing_list_uuid_fk    FK CONSTRAINT     �   ALTER TABLE ONLY delivery.packing_list_entry
    ADD CONSTRAINT packing_list_entry_packing_list_uuid_packing_list_uuid_fk FOREIGN KEY (packing_list_uuid) REFERENCES delivery.packing_list(uuid);
 x   ALTER TABLE ONLY delivery.packing_list_entry DROP CONSTRAINT packing_list_entry_packing_list_uuid_packing_list_uuid_fk;
       delivery          postgres    false    231    232    5276            G           2606    18811 :   packing_list_entry packing_list_entry_sfg_uuid_sfg_uuid_fk    FK CONSTRAINT     �   ALTER TABLE ONLY delivery.packing_list_entry
    ADD CONSTRAINT packing_list_entry_sfg_uuid_sfg_uuid_fk FOREIGN KEY (sfg_uuid) REFERENCES zipper.sfg(uuid);
 f   ALTER TABLE ONLY delivery.packing_list_entry DROP CONSTRAINT packing_list_entry_sfg_uuid_sfg_uuid_fk;
       delivery          postgres    false    232    297    5400            E           2606    98307 <   packing_list packing_list_order_info_uuid_order_info_uuid_fk    FK CONSTRAINT     �   ALTER TABLE ONLY delivery.packing_list
    ADD CONSTRAINT packing_list_order_info_uuid_order_info_uuid_fk FOREIGN KEY (order_info_uuid) REFERENCES zipper.order_info(uuid);
 h   ALTER TABLE ONLY delivery.packing_list DROP CONSTRAINT packing_list_order_info_uuid_order_info_uuid_fk;
       delivery          postgres    false    294    5394    231            H           2606    65657 :   designation designation_department_uuid_department_uuid_fk    FK CONSTRAINT     �   ALTER TABLE ONLY hr.designation
    ADD CONSTRAINT designation_department_uuid_department_uuid_fk FOREIGN KEY (department_uuid) REFERENCES hr.department(uuid);
 `   ALTER TABLE ONLY hr.designation DROP CONSTRAINT designation_department_uuid_department_uuid_fk;
       hr          postgres    false    5282    235    236            I           2606    18816 <   policy_and_notice policy_and_notice_created_by_users_uuid_fk    FK CONSTRAINT     �   ALTER TABLE ONLY hr.policy_and_notice
    ADD CONSTRAINT policy_and_notice_created_by_users_uuid_fk FOREIGN KEY (created_by) REFERENCES hr.users(uuid);
 b   ALTER TABLE ONLY hr.policy_and_notice DROP CONSTRAINT policy_and_notice_created_by_users_uuid_fk;
       hr          postgres    false    237    5290    238            J           2606    18821 0   users users_designation_uuid_designation_uuid_fk    FK CONSTRAINT     �   ALTER TABLE ONLY hr.users
    ADD CONSTRAINT users_designation_uuid_designation_uuid_fk FOREIGN KEY (designation_uuid) REFERENCES hr.designation(uuid);
 V   ALTER TABLE ONLY hr.users DROP CONSTRAINT users_designation_uuid_designation_uuid_fk;
       hr          postgres    false    5284    238    236            K           2606    18826 "   info info_created_by_users_uuid_fk    FK CONSTRAINT     �   ALTER TABLE ONLY lab_dip.info
    ADD CONSTRAINT info_created_by_users_uuid_fk FOREIGN KEY (created_by) REFERENCES hr.users(uuid);
 M   ALTER TABLE ONLY lab_dip.info DROP CONSTRAINT info_created_by_users_uuid_fk;
       lab_dip          postgres    false    238    239    5290            L           2606    18831 ,   info info_order_info_uuid_order_info_uuid_fk    FK CONSTRAINT     �   ALTER TABLE ONLY lab_dip.info
    ADD CONSTRAINT info_order_info_uuid_order_info_uuid_fk FOREIGN KEY (order_info_uuid) REFERENCES zipper.order_info(uuid);
 W   ALTER TABLE ONLY lab_dip.info DROP CONSTRAINT info_order_info_uuid_order_info_uuid_fk;
       lab_dip          postgres    false    5394    294    239            M           2606    106496 3   info info_thread_order_info_uuid_order_info_uuid_fk    FK CONSTRAINT     �   ALTER TABLE ONLY lab_dip.info
    ADD CONSTRAINT info_thread_order_info_uuid_order_info_uuid_fk FOREIGN KEY (thread_order_info_uuid) REFERENCES thread.order_info(uuid);
 ^   ALTER TABLE ONLY lab_dip.info DROP CONSTRAINT info_thread_order_info_uuid_order_info_uuid_fk;
       lab_dip          postgres    false    280    5372    239            N           2606    18836 &   recipe recipe_created_by_users_uuid_fk    FK CONSTRAINT     �   ALTER TABLE ONLY lab_dip.recipe
    ADD CONSTRAINT recipe_created_by_users_uuid_fk FOREIGN KEY (created_by) REFERENCES hr.users(uuid);
 Q   ALTER TABLE ONLY lab_dip.recipe DROP CONSTRAINT recipe_created_by_users_uuid_fk;
       lab_dip          postgres    false    241    238    5290            P           2606    18841 4   recipe_entry recipe_entry_material_uuid_info_uuid_fk    FK CONSTRAINT     �   ALTER TABLE ONLY lab_dip.recipe_entry
    ADD CONSTRAINT recipe_entry_material_uuid_info_uuid_fk FOREIGN KEY (material_uuid) REFERENCES material.info(uuid);
 _   ALTER TABLE ONLY lab_dip.recipe_entry DROP CONSTRAINT recipe_entry_material_uuid_info_uuid_fk;
       lab_dip          postgres    false    5302    247    242            Q           2606    18846 4   recipe_entry recipe_entry_recipe_uuid_recipe_uuid_fk    FK CONSTRAINT     �   ALTER TABLE ONLY lab_dip.recipe_entry
    ADD CONSTRAINT recipe_entry_recipe_uuid_recipe_uuid_fk FOREIGN KEY (recipe_uuid) REFERENCES lab_dip.recipe(uuid);
 _   ALTER TABLE ONLY lab_dip.recipe_entry DROP CONSTRAINT recipe_entry_recipe_uuid_recipe_uuid_fk;
       lab_dip          postgres    false    241    5294    242            O           2606    18851 ,   recipe recipe_lab_dip_info_uuid_info_uuid_fk    FK CONSTRAINT     �   ALTER TABLE ONLY lab_dip.recipe
    ADD CONSTRAINT recipe_lab_dip_info_uuid_info_uuid_fk FOREIGN KEY (lab_dip_info_uuid) REFERENCES lab_dip.info(uuid);
 W   ALTER TABLE ONLY lab_dip.recipe DROP CONSTRAINT recipe_lab_dip_info_uuid_info_uuid_fk;
       lab_dip          postgres    false    241    239    5292            R           2606    18856 2   shade_recipe shade_recipe_created_by_users_uuid_fk    FK CONSTRAINT     �   ALTER TABLE ONLY lab_dip.shade_recipe
    ADD CONSTRAINT shade_recipe_created_by_users_uuid_fk FOREIGN KEY (created_by) REFERENCES hr.users(uuid);
 ]   ALTER TABLE ONLY lab_dip.shade_recipe DROP CONSTRAINT shade_recipe_created_by_users_uuid_fk;
       lab_dip          postgres    false    238    5290    245            S           2606    18861 @   shade_recipe_entry shade_recipe_entry_material_uuid_info_uuid_fk    FK CONSTRAINT     �   ALTER TABLE ONLY lab_dip.shade_recipe_entry
    ADD CONSTRAINT shade_recipe_entry_material_uuid_info_uuid_fk FOREIGN KEY (material_uuid) REFERENCES material.info(uuid);
 k   ALTER TABLE ONLY lab_dip.shade_recipe_entry DROP CONSTRAINT shade_recipe_entry_material_uuid_info_uuid_fk;
       lab_dip          postgres    false    5302    247    246            T           2606    18866 L   shade_recipe_entry shade_recipe_entry_shade_recipe_uuid_shade_recipe_uuid_fk    FK CONSTRAINT     �   ALTER TABLE ONLY lab_dip.shade_recipe_entry
    ADD CONSTRAINT shade_recipe_entry_shade_recipe_uuid_shade_recipe_uuid_fk FOREIGN KEY (shade_recipe_uuid) REFERENCES lab_dip.shade_recipe(uuid);
 w   ALTER TABLE ONLY lab_dip.shade_recipe_entry DROP CONSTRAINT shade_recipe_entry_shade_recipe_uuid_shade_recipe_uuid_fk;
       lab_dip          postgres    false    246    245    5298            U           2606    18871 "   info info_created_by_users_uuid_fk    FK CONSTRAINT     �   ALTER TABLE ONLY material.info
    ADD CONSTRAINT info_created_by_users_uuid_fk FOREIGN KEY (created_by) REFERENCES hr.users(uuid);
 N   ALTER TABLE ONLY material.info DROP CONSTRAINT info_created_by_users_uuid_fk;
       material          postgres    false    247    238    5290            V           2606    18876 &   info info_section_uuid_section_uuid_fk    FK CONSTRAINT     �   ALTER TABLE ONLY material.info
    ADD CONSTRAINT info_section_uuid_section_uuid_fk FOREIGN KEY (section_uuid) REFERENCES material.section(uuid);
 R   ALTER TABLE ONLY material.info DROP CONSTRAINT info_section_uuid_section_uuid_fk;
       material          postgres    false    248    247    5304            W           2606    18881     info info_type_uuid_type_uuid_fk    FK CONSTRAINT     �   ALTER TABLE ONLY material.info
    ADD CONSTRAINT info_type_uuid_type_uuid_fk FOREIGN KEY (type_uuid) REFERENCES material.type(uuid);
 L   ALTER TABLE ONLY material.info DROP CONSTRAINT info_type_uuid_type_uuid_fk;
       material          postgres    false    5312    247    252            X           2606    18886 (   section section_created_by_users_uuid_fk    FK CONSTRAINT     �   ALTER TABLE ONLY material.section
    ADD CONSTRAINT section_created_by_users_uuid_fk FOREIGN KEY (created_by) REFERENCES hr.users(uuid);
 T   ALTER TABLE ONLY material.section DROP CONSTRAINT section_created_by_users_uuid_fk;
       material          postgres    false    238    248    5290            Y           2606    65662 &   stock stock_material_uuid_info_uuid_fk    FK CONSTRAINT     �   ALTER TABLE ONLY material.stock
    ADD CONSTRAINT stock_material_uuid_info_uuid_fk FOREIGN KEY (material_uuid) REFERENCES material.info(uuid);
 R   ALTER TABLE ONLY material.stock DROP CONSTRAINT stock_material_uuid_info_uuid_fk;
       material          postgres    false    249    5302    247            Z           2606    65667 2   stock_to_sfg stock_to_sfg_created_by_users_uuid_fk    FK CONSTRAINT     �   ALTER TABLE ONLY material.stock_to_sfg
    ADD CONSTRAINT stock_to_sfg_created_by_users_uuid_fk FOREIGN KEY (created_by) REFERENCES hr.users(uuid);
 ^   ALTER TABLE ONLY material.stock_to_sfg DROP CONSTRAINT stock_to_sfg_created_by_users_uuid_fk;
       material          postgres    false    5290    250    238            [           2606    18891 4   stock_to_sfg stock_to_sfg_material_uuid_info_uuid_fk    FK CONSTRAINT     �   ALTER TABLE ONLY material.stock_to_sfg
    ADD CONSTRAINT stock_to_sfg_material_uuid_info_uuid_fk FOREIGN KEY (material_uuid) REFERENCES material.info(uuid);
 `   ALTER TABLE ONLY material.stock_to_sfg DROP CONSTRAINT stock_to_sfg_material_uuid_info_uuid_fk;
       material          postgres    false    250    247    5302            \           2606    18896 >   stock_to_sfg stock_to_sfg_order_entry_uuid_order_entry_uuid_fk    FK CONSTRAINT     �   ALTER TABLE ONLY material.stock_to_sfg
    ADD CONSTRAINT stock_to_sfg_order_entry_uuid_order_entry_uuid_fk FOREIGN KEY (order_entry_uuid) REFERENCES zipper.order_entry(uuid);
 j   ALTER TABLE ONLY material.stock_to_sfg DROP CONSTRAINT stock_to_sfg_order_entry_uuid_order_entry_uuid_fk;
       material          postgres    false    292    5392    250            ]           2606    18901     trx trx_created_by_users_uuid_fk    FK CONSTRAINT     �   ALTER TABLE ONLY material.trx
    ADD CONSTRAINT trx_created_by_users_uuid_fk FOREIGN KEY (created_by) REFERENCES hr.users(uuid);
 L   ALTER TABLE ONLY material.trx DROP CONSTRAINT trx_created_by_users_uuid_fk;
       material          postgres    false    238    251    5290            ^           2606    18906 "   trx trx_material_uuid_info_uuid_fk    FK CONSTRAINT     �   ALTER TABLE ONLY material.trx
    ADD CONSTRAINT trx_material_uuid_info_uuid_fk FOREIGN KEY (material_uuid) REFERENCES material.info(uuid);
 N   ALTER TABLE ONLY material.trx DROP CONSTRAINT trx_material_uuid_info_uuid_fk;
       material          postgres    false    5302    247    251            _           2606    18911 "   type type_created_by_users_uuid_fk    FK CONSTRAINT     �   ALTER TABLE ONLY material.type
    ADD CONSTRAINT type_created_by_users_uuid_fk FOREIGN KEY (created_by) REFERENCES hr.users(uuid);
 N   ALTER TABLE ONLY material.type DROP CONSTRAINT type_created_by_users_uuid_fk;
       material          postgres    false    5290    252    238            `           2606    18916 "   used used_created_by_users_uuid_fk    FK CONSTRAINT     �   ALTER TABLE ONLY material.used
    ADD CONSTRAINT used_created_by_users_uuid_fk FOREIGN KEY (created_by) REFERENCES hr.users(uuid);
 N   ALTER TABLE ONLY material.used DROP CONSTRAINT used_created_by_users_uuid_fk;
       material          postgres    false    253    5290    238            a           2606    18921 $   used used_material_uuid_info_uuid_fk    FK CONSTRAINT     �   ALTER TABLE ONLY material.used
    ADD CONSTRAINT used_material_uuid_info_uuid_fk FOREIGN KEY (material_uuid) REFERENCES material.info(uuid);
 P   ALTER TABLE ONLY material.used DROP CONSTRAINT used_material_uuid_info_uuid_fk;
       material          postgres    false    247    253    5302            b           2606    18926 $   buyer buyer_created_by_users_uuid_fk    FK CONSTRAINT     �   ALTER TABLE ONLY public.buyer
    ADD CONSTRAINT buyer_created_by_users_uuid_fk FOREIGN KEY (created_by) REFERENCES hr.users(uuid);
 N   ALTER TABLE ONLY public.buyer DROP CONSTRAINT buyer_created_by_users_uuid_fk;
       public          postgres    false    5290    254    238            c           2606    18931 (   factory factory_created_by_users_uuid_fk    FK CONSTRAINT     �   ALTER TABLE ONLY public.factory
    ADD CONSTRAINT factory_created_by_users_uuid_fk FOREIGN KEY (created_by) REFERENCES hr.users(uuid);
 R   ALTER TABLE ONLY public.factory DROP CONSTRAINT factory_created_by_users_uuid_fk;
       public          postgres    false    5290    255    238            d           2606    18936 (   factory factory_party_uuid_party_uuid_fk    FK CONSTRAINT     �   ALTER TABLE ONLY public.factory
    ADD CONSTRAINT factory_party_uuid_party_uuid_fk FOREIGN KEY (party_uuid) REFERENCES public.party(uuid);
 R   ALTER TABLE ONLY public.factory DROP CONSTRAINT factory_party_uuid_party_uuid_fk;
       public          postgres    false    5334    255    258            �           2606    73789 (   machine machine_created_by_users_uuid_fk    FK CONSTRAINT     �   ALTER TABLE ONLY public.machine
    ADD CONSTRAINT machine_created_by_users_uuid_fk FOREIGN KEY (created_by) REFERENCES hr.users(uuid);
 R   ALTER TABLE ONLY public.machine DROP CONSTRAINT machine_created_by_users_uuid_fk;
       public          postgres    false    305    238    5290            e           2606    18941 ,   marketing marketing_created_by_users_uuid_fk    FK CONSTRAINT     �   ALTER TABLE ONLY public.marketing
    ADD CONSTRAINT marketing_created_by_users_uuid_fk FOREIGN KEY (created_by) REFERENCES hr.users(uuid);
 V   ALTER TABLE ONLY public.marketing DROP CONSTRAINT marketing_created_by_users_uuid_fk;
       public          postgres    false    5290    256    238            f           2606    18946 +   marketing marketing_user_uuid_users_uuid_fk    FK CONSTRAINT     �   ALTER TABLE ONLY public.marketing
    ADD CONSTRAINT marketing_user_uuid_users_uuid_fk FOREIGN KEY (user_uuid) REFERENCES hr.users(uuid);
 U   ALTER TABLE ONLY public.marketing DROP CONSTRAINT marketing_user_uuid_users_uuid_fk;
       public          postgres    false    238    5290    256            g           2606    18951 2   merchandiser merchandiser_created_by_users_uuid_fk    FK CONSTRAINT     �   ALTER TABLE ONLY public.merchandiser
    ADD CONSTRAINT merchandiser_created_by_users_uuid_fk FOREIGN KEY (created_by) REFERENCES hr.users(uuid);
 \   ALTER TABLE ONLY public.merchandiser DROP CONSTRAINT merchandiser_created_by_users_uuid_fk;
       public          postgres    false    257    5290    238            h           2606    18956 2   merchandiser merchandiser_party_uuid_party_uuid_fk    FK CONSTRAINT     �   ALTER TABLE ONLY public.merchandiser
    ADD CONSTRAINT merchandiser_party_uuid_party_uuid_fk FOREIGN KEY (party_uuid) REFERENCES public.party(uuid);
 \   ALTER TABLE ONLY public.merchandiser DROP CONSTRAINT merchandiser_party_uuid_party_uuid_fk;
       public          postgres    false    258    257    5334            i           2606    18961 $   party party_created_by_users_uuid_fk    FK CONSTRAINT     �   ALTER TABLE ONLY public.party
    ADD CONSTRAINT party_created_by_users_uuid_fk FOREIGN KEY (created_by) REFERENCES hr.users(uuid);
 N   ALTER TABLE ONLY public.party DROP CONSTRAINT party_created_by_users_uuid_fk;
       public          postgres    false    5290    258    238            j           2606    18966 0   description description_created_by_users_uuid_fk    FK CONSTRAINT     �   ALTER TABLE ONLY purchase.description
    ADD CONSTRAINT description_created_by_users_uuid_fk FOREIGN KEY (created_by) REFERENCES hr.users(uuid);
 \   ALTER TABLE ONLY purchase.description DROP CONSTRAINT description_created_by_users_uuid_fk;
       purchase          postgres    false    262    5290    238            k           2606    18971 2   description description_vendor_uuid_vendor_uuid_fk    FK CONSTRAINT     �   ALTER TABLE ONLY purchase.description
    ADD CONSTRAINT description_vendor_uuid_vendor_uuid_fk FOREIGN KEY (vendor_uuid) REFERENCES purchase.vendor(uuid);
 ^   ALTER TABLE ONLY purchase.description DROP CONSTRAINT description_vendor_uuid_vendor_uuid_fk;
       purchase          postgres    false    262    5344    264            l           2606    18976 &   entry entry_material_uuid_info_uuid_fk    FK CONSTRAINT     �   ALTER TABLE ONLY purchase.entry
    ADD CONSTRAINT entry_material_uuid_info_uuid_fk FOREIGN KEY (material_uuid) REFERENCES material.info(uuid);
 R   ALTER TABLE ONLY purchase.entry DROP CONSTRAINT entry_material_uuid_info_uuid_fk;
       purchase          postgres    false    247    263    5302            m           2606    18981 9   entry entry_purchase_description_uuid_description_uuid_fk    FK CONSTRAINT     �   ALTER TABLE ONLY purchase.entry
    ADD CONSTRAINT entry_purchase_description_uuid_description_uuid_fk FOREIGN KEY (purchase_description_uuid) REFERENCES purchase.description(uuid);
 e   ALTER TABLE ONLY purchase.entry DROP CONSTRAINT entry_purchase_description_uuid_description_uuid_fk;
       purchase          postgres    false    5340    262    263            n           2606    18986 &   vendor vendor_created_by_users_uuid_fk    FK CONSTRAINT     �   ALTER TABLE ONLY purchase.vendor
    ADD CONSTRAINT vendor_created_by_users_uuid_fk FOREIGN KEY (created_by) REFERENCES hr.users(uuid);
 R   ALTER TABLE ONLY purchase.vendor DROP CONSTRAINT vendor_created_by_users_uuid_fk;
       purchase          postgres    false    264    5290    238            �           2606    73808 6   assembly_stock assembly_stock_created_by_users_uuid_fk    FK CONSTRAINT     �   ALTER TABLE ONLY slider.assembly_stock
    ADD CONSTRAINT assembly_stock_created_by_users_uuid_fk FOREIGN KEY (created_by) REFERENCES hr.users(uuid);
 `   ALTER TABLE ONLY slider.assembly_stock DROP CONSTRAINT assembly_stock_created_by_users_uuid_fk;
       slider          postgres    false    238    306    5290            o           2606    18991 B   coloring_transaction coloring_transaction_created_by_users_uuid_fk    FK CONSTRAINT     �   ALTER TABLE ONLY slider.coloring_transaction
    ADD CONSTRAINT coloring_transaction_created_by_users_uuid_fk FOREIGN KEY (created_by) REFERENCES hr.users(uuid);
 l   ALTER TABLE ONLY slider.coloring_transaction DROP CONSTRAINT coloring_transaction_created_by_users_uuid_fk;
       slider          postgres    false    265    238    5290            p           2606    18996 L   coloring_transaction coloring_transaction_order_info_uuid_order_info_uuid_fk    FK CONSTRAINT     �   ALTER TABLE ONLY slider.coloring_transaction
    ADD CONSTRAINT coloring_transaction_order_info_uuid_order_info_uuid_fk FOREIGN KEY (order_info_uuid) REFERENCES zipper.order_info(uuid);
 v   ALTER TABLE ONLY slider.coloring_transaction DROP CONSTRAINT coloring_transaction_order_info_uuid_order_info_uuid_fk;
       slider          postgres    false    294    5394    265            q           2606    19001 B   coloring_transaction coloring_transaction_stock_uuid_stock_uuid_fk    FK CONSTRAINT     �   ALTER TABLE ONLY slider.coloring_transaction
    ADD CONSTRAINT coloring_transaction_stock_uuid_stock_uuid_fk FOREIGN KEY (stock_uuid) REFERENCES slider.stock(uuid);
 l   ALTER TABLE ONLY slider.coloring_transaction DROP CONSTRAINT coloring_transaction_stock_uuid_stock_uuid_fk;
       slider          postgres    false    265    5356    270            r           2606    65682 3   die_casting die_casting_end_type_properties_uuid_fk    FK CONSTRAINT     �   ALTER TABLE ONLY slider.die_casting
    ADD CONSTRAINT die_casting_end_type_properties_uuid_fk FOREIGN KEY (end_type) REFERENCES public.properties(uuid);
 ]   ALTER TABLE ONLY slider.die_casting DROP CONSTRAINT die_casting_end_type_properties_uuid_fk;
       slider          postgres    false    5336    266    259            s           2606    65672 /   die_casting die_casting_item_properties_uuid_fk    FK CONSTRAINT     �   ALTER TABLE ONLY slider.die_casting
    ADD CONSTRAINT die_casting_item_properties_uuid_fk FOREIGN KEY (item) REFERENCES public.properties(uuid);
 Y   ALTER TABLE ONLY slider.die_casting DROP CONSTRAINT die_casting_item_properties_uuid_fk;
       slider          postgres    false    259    266    5336            t           2606    65692 4   die_casting die_casting_logo_type_properties_uuid_fk    FK CONSTRAINT     �   ALTER TABLE ONLY slider.die_casting
    ADD CONSTRAINT die_casting_logo_type_properties_uuid_fk FOREIGN KEY (logo_type) REFERENCES public.properties(uuid);
 ^   ALTER TABLE ONLY slider.die_casting DROP CONSTRAINT die_casting_logo_type_properties_uuid_fk;
       slider          postgres    false    259    266    5336            y           2606    19006 F   die_casting_production die_casting_production_created_by_users_uuid_fk    FK CONSTRAINT     �   ALTER TABLE ONLY slider.die_casting_production
    ADD CONSTRAINT die_casting_production_created_by_users_uuid_fk FOREIGN KEY (created_by) REFERENCES hr.users(uuid);
 p   ALTER TABLE ONLY slider.die_casting_production DROP CONSTRAINT die_casting_production_created_by_users_uuid_fk;
       slider          postgres    false    5290    238    267            z           2606    19011 R   die_casting_production die_casting_production_die_casting_uuid_die_casting_uuid_fk    FK CONSTRAINT     �   ALTER TABLE ONLY slider.die_casting_production
    ADD CONSTRAINT die_casting_production_die_casting_uuid_die_casting_uuid_fk FOREIGN KEY (die_casting_uuid) REFERENCES slider.die_casting(uuid);
 |   ALTER TABLE ONLY slider.die_casting_production DROP CONSTRAINT die_casting_production_die_casting_uuid_die_casting_uuid_fk;
       slider          postgres    false    267    266    5348            {           2606    73739 V   die_casting_production die_casting_production_order_description_uuid_order_description    FK CONSTRAINT     �   ALTER TABLE ONLY slider.die_casting_production
    ADD CONSTRAINT die_casting_production_order_description_uuid_order_description FOREIGN KEY (order_description_uuid) REFERENCES zipper.order_description(uuid);
 �   ALTER TABLE ONLY slider.die_casting_production DROP CONSTRAINT die_casting_production_order_description_uuid_order_description;
       slider          postgres    false    267    291    5390            u           2606    65687 6   die_casting die_casting_puller_type_properties_uuid_fk    FK CONSTRAINT     �   ALTER TABLE ONLY slider.die_casting
    ADD CONSTRAINT die_casting_puller_type_properties_uuid_fk FOREIGN KEY (puller_type) REFERENCES public.properties(uuid);
 `   ALTER TABLE ONLY slider.die_casting DROP CONSTRAINT die_casting_puller_type_properties_uuid_fk;
       slider          postgres    false    259    266    5336            v           2606    65697 <   die_casting die_casting_slider_body_shape_properties_uuid_fk    FK CONSTRAINT     �   ALTER TABLE ONLY slider.die_casting
    ADD CONSTRAINT die_casting_slider_body_shape_properties_uuid_fk FOREIGN KEY (slider_body_shape) REFERENCES public.properties(uuid);
 f   ALTER TABLE ONLY slider.die_casting DROP CONSTRAINT die_casting_slider_body_shape_properties_uuid_fk;
       slider          postgres    false    266    5336    259            w           2606    139377 6   die_casting die_casting_slider_link_properties_uuid_fk    FK CONSTRAINT     �   ALTER TABLE ONLY slider.die_casting
    ADD CONSTRAINT die_casting_slider_link_properties_uuid_fk FOREIGN KEY (slider_link) REFERENCES public.properties(uuid);
 `   ALTER TABLE ONLY slider.die_casting DROP CONSTRAINT die_casting_slider_link_properties_uuid_fk;
       slider          postgres    false    259    266    5336            �           2606    81946 ]   die_casting_to_assembly_stock die_casting_to_assembly_stock_assembly_stock_uuid_assembly_stoc    FK CONSTRAINT     �   ALTER TABLE ONLY slider.die_casting_to_assembly_stock
    ADD CONSTRAINT die_casting_to_assembly_stock_assembly_stock_uuid_assembly_stoc FOREIGN KEY (assembly_stock_uuid) REFERENCES slider.assembly_stock(uuid);
 �   ALTER TABLE ONLY slider.die_casting_to_assembly_stock DROP CONSTRAINT die_casting_to_assembly_stock_assembly_stock_uuid_assembly_stoc;
       slider          postgres    false    306    307    5418            �           2606    81951 T   die_casting_to_assembly_stock die_casting_to_assembly_stock_created_by_users_uuid_fk    FK CONSTRAINT     �   ALTER TABLE ONLY slider.die_casting_to_assembly_stock
    ADD CONSTRAINT die_casting_to_assembly_stock_created_by_users_uuid_fk FOREIGN KEY (created_by) REFERENCES hr.users(uuid);
 ~   ALTER TABLE ONLY slider.die_casting_to_assembly_stock DROP CONSTRAINT die_casting_to_assembly_stock_created_by_users_uuid_fk;
       slider          postgres    false    238    5290    307            |           2606    19016 H   die_casting_transaction die_casting_transaction_created_by_users_uuid_fk    FK CONSTRAINT     �   ALTER TABLE ONLY slider.die_casting_transaction
    ADD CONSTRAINT die_casting_transaction_created_by_users_uuid_fk FOREIGN KEY (created_by) REFERENCES hr.users(uuid);
 r   ALTER TABLE ONLY slider.die_casting_transaction DROP CONSTRAINT die_casting_transaction_created_by_users_uuid_fk;
       slider          postgres    false    5290    268    238            }           2606    19021 T   die_casting_transaction die_casting_transaction_die_casting_uuid_die_casting_uuid_fk    FK CONSTRAINT     �   ALTER TABLE ONLY slider.die_casting_transaction
    ADD CONSTRAINT die_casting_transaction_die_casting_uuid_die_casting_uuid_fk FOREIGN KEY (die_casting_uuid) REFERENCES slider.die_casting(uuid);
 ~   ALTER TABLE ONLY slider.die_casting_transaction DROP CONSTRAINT die_casting_transaction_die_casting_uuid_die_casting_uuid_fk;
       slider          postgres    false    5348    266    268            ~           2606    19026 H   die_casting_transaction die_casting_transaction_stock_uuid_stock_uuid_fk    FK CONSTRAINT     �   ALTER TABLE ONLY slider.die_casting_transaction
    ADD CONSTRAINT die_casting_transaction_stock_uuid_stock_uuid_fk FOREIGN KEY (stock_uuid) REFERENCES slider.stock(uuid);
 r   ALTER TABLE ONLY slider.die_casting_transaction DROP CONSTRAINT die_casting_transaction_stock_uuid_stock_uuid_fk;
       slider          postgres    false    5356    268    270            x           2606    65677 8   die_casting die_casting_zipper_number_properties_uuid_fk    FK CONSTRAINT     �   ALTER TABLE ONLY slider.die_casting
    ADD CONSTRAINT die_casting_zipper_number_properties_uuid_fk FOREIGN KEY (zipper_number) REFERENCES public.properties(uuid);
 b   ALTER TABLE ONLY slider.die_casting DROP CONSTRAINT die_casting_zipper_number_properties_uuid_fk;
       slider          postgres    false    259    266    5336                       2606    19031 .   production production_created_by_users_uuid_fk    FK CONSTRAINT     �   ALTER TABLE ONLY slider.production
    ADD CONSTRAINT production_created_by_users_uuid_fk FOREIGN KEY (created_by) REFERENCES hr.users(uuid);
 X   ALTER TABLE ONLY slider.production DROP CONSTRAINT production_created_by_users_uuid_fk;
       slider          postgres    false    238    269    5290            �           2606    19036 .   production production_stock_uuid_stock_uuid_fk    FK CONSTRAINT     �   ALTER TABLE ONLY slider.production
    ADD CONSTRAINT production_stock_uuid_stock_uuid_fk FOREIGN KEY (stock_uuid) REFERENCES slider.stock(uuid);
 X   ALTER TABLE ONLY slider.production DROP CONSTRAINT production_stock_uuid_stock_uuid_fk;
       slider          postgres    false    269    5356    270            �           2606    19041 <   stock stock_order_description_uuid_order_description_uuid_fk    FK CONSTRAINT     �   ALTER TABLE ONLY slider.stock
    ADD CONSTRAINT stock_order_description_uuid_order_description_uuid_fk FOREIGN KEY (order_description_uuid) REFERENCES zipper.order_description(uuid);
 f   ALTER TABLE ONLY slider.stock DROP CONSTRAINT stock_order_description_uuid_order_description_uuid_fk;
       slider          postgres    false    5390    291    270            �           2606    82054 B   transaction transaction_assembly_stock_uuid_assembly_stock_uuid_fk    FK CONSTRAINT     �   ALTER TABLE ONLY slider.transaction
    ADD CONSTRAINT transaction_assembly_stock_uuid_assembly_stock_uuid_fk FOREIGN KEY (assembly_stock_uuid) REFERENCES slider.assembly_stock(uuid);
 l   ALTER TABLE ONLY slider.transaction DROP CONSTRAINT transaction_assembly_stock_uuid_assembly_stock_uuid_fk;
       slider          postgres    false    5418    306    271            �           2606    19046 0   transaction transaction_created_by_users_uuid_fk    FK CONSTRAINT     �   ALTER TABLE ONLY slider.transaction
    ADD CONSTRAINT transaction_created_by_users_uuid_fk FOREIGN KEY (created_by) REFERENCES hr.users(uuid);
 Z   ALTER TABLE ONLY slider.transaction DROP CONSTRAINT transaction_created_by_users_uuid_fk;
       slider          postgres    false    238    5290    271            �           2606    19051 0   transaction transaction_stock_uuid_stock_uuid_fk    FK CONSTRAINT     �   ALTER TABLE ONLY slider.transaction
    ADD CONSTRAINT transaction_stock_uuid_stock_uuid_fk FOREIGN KEY (stock_uuid) REFERENCES slider.stock(uuid);
 Z   ALTER TABLE ONLY slider.transaction DROP CONSTRAINT transaction_stock_uuid_stock_uuid_fk;
       slider          postgres    false    270    271    5356            �           2606    19056 <   trx_against_stock trx_against_stock_created_by_users_uuid_fk    FK CONSTRAINT     �   ALTER TABLE ONLY slider.trx_against_stock
    ADD CONSTRAINT trx_against_stock_created_by_users_uuid_fk FOREIGN KEY (created_by) REFERENCES hr.users(uuid);
 f   ALTER TABLE ONLY slider.trx_against_stock DROP CONSTRAINT trx_against_stock_created_by_users_uuid_fk;
       slider          postgres    false    272    5290    238            �           2606    19061 H   trx_against_stock trx_against_stock_die_casting_uuid_die_casting_uuid_fk    FK CONSTRAINT     �   ALTER TABLE ONLY slider.trx_against_stock
    ADD CONSTRAINT trx_against_stock_die_casting_uuid_die_casting_uuid_fk FOREIGN KEY (die_casting_uuid) REFERENCES slider.die_casting(uuid);
 r   ALTER TABLE ONLY slider.trx_against_stock DROP CONSTRAINT trx_against_stock_die_casting_uuid_die_casting_uuid_fk;
       slider          postgres    false    5348    266    272            �           2606    19066 +   batch batch_coning_created_by_users_uuid_fk    FK CONSTRAINT     �   ALTER TABLE ONLY thread.batch
    ADD CONSTRAINT batch_coning_created_by_users_uuid_fk FOREIGN KEY (coning_created_by) REFERENCES hr.users(uuid);
 U   ALTER TABLE ONLY thread.batch DROP CONSTRAINT batch_coning_created_by_users_uuid_fk;
       thread          postgres    false    5290    238    274            �           2606    19071 $   batch batch_created_by_users_uuid_fk    FK CONSTRAINT     �   ALTER TABLE ONLY thread.batch
    ADD CONSTRAINT batch_created_by_users_uuid_fk FOREIGN KEY (created_by) REFERENCES hr.users(uuid);
 N   ALTER TABLE ONLY thread.batch DROP CONSTRAINT batch_created_by_users_uuid_fk;
       thread          postgres    false    238    274    5290            �           2606    19076 +   batch batch_dyeing_created_by_users_uuid_fk    FK CONSTRAINT     �   ALTER TABLE ONLY thread.batch
    ADD CONSTRAINT batch_dyeing_created_by_users_uuid_fk FOREIGN KEY (dyeing_created_by) REFERENCES hr.users(uuid);
 U   ALTER TABLE ONLY thread.batch DROP CONSTRAINT batch_dyeing_created_by_users_uuid_fk;
       thread          postgres    false    5290    238    274            �           2606    19081 )   batch batch_dyeing_operator_users_uuid_fk    FK CONSTRAINT     �   ALTER TABLE ONLY thread.batch
    ADD CONSTRAINT batch_dyeing_operator_users_uuid_fk FOREIGN KEY (dyeing_operator) REFERENCES hr.users(uuid);
 S   ALTER TABLE ONLY thread.batch DROP CONSTRAINT batch_dyeing_operator_users_uuid_fk;
       thread          postgres    false    238    5290    274            �           2606    19086 +   batch batch_dyeing_supervisor_users_uuid_fk    FK CONSTRAINT     �   ALTER TABLE ONLY thread.batch
    ADD CONSTRAINT batch_dyeing_supervisor_users_uuid_fk FOREIGN KEY (dyeing_supervisor) REFERENCES hr.users(uuid);
 U   ALTER TABLE ONLY thread.batch DROP CONSTRAINT batch_dyeing_supervisor_users_uuid_fk;
       thread          postgres    false    5290    238    274            �           2606    19091 0   batch_entry batch_entry_batch_uuid_batch_uuid_fk    FK CONSTRAINT     �   ALTER TABLE ONLY thread.batch_entry
    ADD CONSTRAINT batch_entry_batch_uuid_batch_uuid_fk FOREIGN KEY (batch_uuid) REFERENCES thread.batch(uuid);
 Z   ALTER TABLE ONLY thread.batch_entry DROP CONSTRAINT batch_entry_batch_uuid_batch_uuid_fk;
       thread          postgres    false    274    5362    275            �           2606    19096 <   batch_entry batch_entry_order_entry_uuid_order_entry_uuid_fk    FK CONSTRAINT     �   ALTER TABLE ONLY thread.batch_entry
    ADD CONSTRAINT batch_entry_order_entry_uuid_order_entry_uuid_fk FOREIGN KEY (order_entry_uuid) REFERENCES thread.order_entry(uuid);
 f   ALTER TABLE ONLY thread.batch_entry DROP CONSTRAINT batch_entry_order_entry_uuid_order_entry_uuid_fk;
       thread          postgres    false    275    5370    278            �           2606    131216 R   batch_entry_production batch_entry_production_batch_entry_uuid_batch_entry_uuid_fk    FK CONSTRAINT     �   ALTER TABLE ONLY thread.batch_entry_production
    ADD CONSTRAINT batch_entry_production_batch_entry_uuid_batch_entry_uuid_fk FOREIGN KEY (batch_entry_uuid) REFERENCES thread.batch_entry(uuid);
 |   ALTER TABLE ONLY thread.batch_entry_production DROP CONSTRAINT batch_entry_production_batch_entry_uuid_batch_entry_uuid_fk;
       thread          postgres    false    5364    275    314            �           2606    131221 F   batch_entry_production batch_entry_production_created_by_users_uuid_fk    FK CONSTRAINT     �   ALTER TABLE ONLY thread.batch_entry_production
    ADD CONSTRAINT batch_entry_production_created_by_users_uuid_fk FOREIGN KEY (created_by) REFERENCES hr.users(uuid);
 p   ALTER TABLE ONLY thread.batch_entry_production DROP CONSTRAINT batch_entry_production_created_by_users_uuid_fk;
       thread          postgres    false    314    238    5290            �           2606    131226 D   batch_entry_trx batch_entry_trx_batch_entry_uuid_batch_entry_uuid_fk    FK CONSTRAINT     �   ALTER TABLE ONLY thread.batch_entry_trx
    ADD CONSTRAINT batch_entry_trx_batch_entry_uuid_batch_entry_uuid_fk FOREIGN KEY (batch_entry_uuid) REFERENCES thread.batch_entry(uuid);
 n   ALTER TABLE ONLY thread.batch_entry_trx DROP CONSTRAINT batch_entry_trx_batch_entry_uuid_batch_entry_uuid_fk;
       thread          postgres    false    275    5364    315            �           2606    131231 8   batch_entry_trx batch_entry_trx_created_by_users_uuid_fk    FK CONSTRAINT     �   ALTER TABLE ONLY thread.batch_entry_trx
    ADD CONSTRAINT batch_entry_trx_created_by_users_uuid_fk FOREIGN KEY (created_by) REFERENCES hr.users(uuid);
 b   ALTER TABLE ONLY thread.batch_entry_trx DROP CONSTRAINT batch_entry_trx_created_by_users_uuid_fk;
       thread          postgres    false    315    238    5290            �           2606    19101 (   batch batch_lab_created_by_users_uuid_fk    FK CONSTRAINT     �   ALTER TABLE ONLY thread.batch
    ADD CONSTRAINT batch_lab_created_by_users_uuid_fk FOREIGN KEY (lab_created_by) REFERENCES hr.users(uuid);
 R   ALTER TABLE ONLY thread.batch DROP CONSTRAINT batch_lab_created_by_users_uuid_fk;
       thread          postgres    false    274    5290    238            �           2606    73794 (   batch batch_machine_uuid_machine_uuid_fk    FK CONSTRAINT     �   ALTER TABLE ONLY thread.batch
    ADD CONSTRAINT batch_machine_uuid_machine_uuid_fk FOREIGN KEY (machine_uuid) REFERENCES public.machine(uuid);
 R   ALTER TABLE ONLY thread.batch DROP CONSTRAINT batch_machine_uuid_machine_uuid_fk;
       thread          postgres    false    305    5416    274            �           2606    19111 !   batch batch_pass_by_users_uuid_fk    FK CONSTRAINT     ~   ALTER TABLE ONLY thread.batch
    ADD CONSTRAINT batch_pass_by_users_uuid_fk FOREIGN KEY (pass_by) REFERENCES hr.users(uuid);
 K   ALTER TABLE ONLY thread.batch DROP CONSTRAINT batch_pass_by_users_uuid_fk;
       thread          postgres    false    5290    238    274            �           2606    19116 /   batch batch_yarn_issue_created_by_users_uuid_fk    FK CONSTRAINT     �   ALTER TABLE ONLY thread.batch
    ADD CONSTRAINT batch_yarn_issue_created_by_users_uuid_fk FOREIGN KEY (yarn_issue_created_by) REFERENCES hr.users(uuid);
 Y   ALTER TABLE ONLY thread.batch DROP CONSTRAINT batch_yarn_issue_created_by_users_uuid_fk;
       thread          postgres    false    274    5290    238            �           2606    155762 '   challan challan_assign_to_users_uuid_fk    FK CONSTRAINT     �   ALTER TABLE ONLY thread.challan
    ADD CONSTRAINT challan_assign_to_users_uuid_fk FOREIGN KEY (assign_to) REFERENCES hr.users(uuid);
 Q   ALTER TABLE ONLY thread.challan DROP CONSTRAINT challan_assign_to_users_uuid_fk;
       thread          postgres    false    238    5290    316            �           2606    131241 (   challan challan_created_by_users_uuid_fk    FK CONSTRAINT     �   ALTER TABLE ONLY thread.challan
    ADD CONSTRAINT challan_created_by_users_uuid_fk FOREIGN KEY (created_by) REFERENCES hr.users(uuid);
 R   ALTER TABLE ONLY thread.challan DROP CONSTRAINT challan_created_by_users_uuid_fk;
       thread          postgres    false    238    316    5290            �           2606    131246 8   challan_entry challan_entry_challan_uuid_challan_uuid_fk    FK CONSTRAINT     �   ALTER TABLE ONLY thread.challan_entry
    ADD CONSTRAINT challan_entry_challan_uuid_challan_uuid_fk FOREIGN KEY (challan_uuid) REFERENCES thread.challan(uuid);
 b   ALTER TABLE ONLY thread.challan_entry DROP CONSTRAINT challan_entry_challan_uuid_challan_uuid_fk;
       thread          postgres    false    316    317    5432            �           2606    131256 4   challan_entry challan_entry_created_by_users_uuid_fk    FK CONSTRAINT     �   ALTER TABLE ONLY thread.challan_entry
    ADD CONSTRAINT challan_entry_created_by_users_uuid_fk FOREIGN KEY (created_by) REFERENCES hr.users(uuid);
 ^   ALTER TABLE ONLY thread.challan_entry DROP CONSTRAINT challan_entry_created_by_users_uuid_fk;
       thread          postgres    false    238    317    5290            �           2606    131251 @   challan_entry challan_entry_order_entry_uuid_order_entry_uuid_fk    FK CONSTRAINT     �   ALTER TABLE ONLY thread.challan_entry
    ADD CONSTRAINT challan_entry_order_entry_uuid_order_entry_uuid_fk FOREIGN KEY (order_entry_uuid) REFERENCES thread.order_entry(uuid);
 j   ALTER TABLE ONLY thread.challan_entry DROP CONSTRAINT challan_entry_order_entry_uuid_order_entry_uuid_fk;
       thread          postgres    false    278    5370    317            �           2606    131236 2   challan challan_order_info_uuid_order_info_uuid_fk    FK CONSTRAINT     �   ALTER TABLE ONLY thread.challan
    ADD CONSTRAINT challan_order_info_uuid_order_info_uuid_fk FOREIGN KEY (order_info_uuid) REFERENCES thread.order_info(uuid);
 \   ALTER TABLE ONLY thread.challan DROP CONSTRAINT challan_order_info_uuid_order_info_uuid_fk;
       thread          postgres    false    5372    280    316            �           2606    19121 2   count_length count_length_created_by_users_uuid_fk    FK CONSTRAINT     �   ALTER TABLE ONLY thread.count_length
    ADD CONSTRAINT count_length_created_by_users_uuid_fk FOREIGN KEY (created_by) REFERENCES hr.users(uuid);
 \   ALTER TABLE ONLY thread.count_length DROP CONSTRAINT count_length_created_by_users_uuid_fk;
       thread          postgres    false    238    276    5290            �           2606    19126 4   dyes_category dyes_category_created_by_users_uuid_fk    FK CONSTRAINT     �   ALTER TABLE ONLY thread.dyes_category
    ADD CONSTRAINT dyes_category_created_by_users_uuid_fk FOREIGN KEY (created_by) REFERENCES hr.users(uuid);
 ^   ALTER TABLE ONLY thread.dyes_category DROP CONSTRAINT dyes_category_created_by_users_uuid_fk;
       thread          postgres    false    5290    277    238            �           2606    19136 >   order_entry order_entry_count_length_uuid_count_length_uuid_fk    FK CONSTRAINT     �   ALTER TABLE ONLY thread.order_entry
    ADD CONSTRAINT order_entry_count_length_uuid_count_length_uuid_fk FOREIGN KEY (count_length_uuid) REFERENCES thread.count_length(uuid);
 h   ALTER TABLE ONLY thread.order_entry DROP CONSTRAINT order_entry_count_length_uuid_count_length_uuid_fk;
       thread          postgres    false    5366    278    276            �           2606    19141 0   order_entry order_entry_created_by_users_uuid_fk    FK CONSTRAINT     �   ALTER TABLE ONLY thread.order_entry
    ADD CONSTRAINT order_entry_created_by_users_uuid_fk FOREIGN KEY (created_by) REFERENCES hr.users(uuid);
 Z   ALTER TABLE ONLY thread.order_entry DROP CONSTRAINT order_entry_created_by_users_uuid_fk;
       thread          postgres    false    5290    278    238            �           2606    19146 :   order_entry order_entry_order_info_uuid_order_info_uuid_fk    FK CONSTRAINT     �   ALTER TABLE ONLY thread.order_entry
    ADD CONSTRAINT order_entry_order_info_uuid_order_info_uuid_fk FOREIGN KEY (order_info_uuid) REFERENCES thread.order_info(uuid);
 d   ALTER TABLE ONLY thread.order_entry DROP CONSTRAINT order_entry_order_info_uuid_order_info_uuid_fk;
       thread          postgres    false    5372    278    280            �           2606    122895 2   order_entry order_entry_recipe_uuid_recipe_uuid_fk    FK CONSTRAINT     �   ALTER TABLE ONLY thread.order_entry
    ADD CONSTRAINT order_entry_recipe_uuid_recipe_uuid_fk FOREIGN KEY (recipe_uuid) REFERENCES lab_dip.recipe(uuid);
 \   ALTER TABLE ONLY thread.order_entry DROP CONSTRAINT order_entry_recipe_uuid_recipe_uuid_fk;
       thread          postgres    false    241    278    5294            �           2606    19156 .   order_info order_info_buyer_uuid_buyer_uuid_fk    FK CONSTRAINT     �   ALTER TABLE ONLY thread.order_info
    ADD CONSTRAINT order_info_buyer_uuid_buyer_uuid_fk FOREIGN KEY (buyer_uuid) REFERENCES public.buyer(uuid);
 X   ALTER TABLE ONLY thread.order_info DROP CONSTRAINT order_info_buyer_uuid_buyer_uuid_fk;
       thread          postgres    false    5318    280    254            �           2606    19161 .   order_info order_info_created_by_users_uuid_fk    FK CONSTRAINT     �   ALTER TABLE ONLY thread.order_info
    ADD CONSTRAINT order_info_created_by_users_uuid_fk FOREIGN KEY (created_by) REFERENCES hr.users(uuid);
 X   ALTER TABLE ONLY thread.order_info DROP CONSTRAINT order_info_created_by_users_uuid_fk;
       thread          postgres    false    5290    280    238            �           2606    19166 2   order_info order_info_factory_uuid_factory_uuid_fk    FK CONSTRAINT     �   ALTER TABLE ONLY thread.order_info
    ADD CONSTRAINT order_info_factory_uuid_factory_uuid_fk FOREIGN KEY (factory_uuid) REFERENCES public.factory(uuid);
 \   ALTER TABLE ONLY thread.order_info DROP CONSTRAINT order_info_factory_uuid_factory_uuid_fk;
       thread          postgres    false    5322    280    255            �           2606    19171 6   order_info order_info_marketing_uuid_marketing_uuid_fk    FK CONSTRAINT     �   ALTER TABLE ONLY thread.order_info
    ADD CONSTRAINT order_info_marketing_uuid_marketing_uuid_fk FOREIGN KEY (marketing_uuid) REFERENCES public.marketing(uuid);
 `   ALTER TABLE ONLY thread.order_info DROP CONSTRAINT order_info_marketing_uuid_marketing_uuid_fk;
       thread          postgres    false    280    5326    256            �           2606    19176 <   order_info order_info_merchandiser_uuid_merchandiser_uuid_fk    FK CONSTRAINT     �   ALTER TABLE ONLY thread.order_info
    ADD CONSTRAINT order_info_merchandiser_uuid_merchandiser_uuid_fk FOREIGN KEY (merchandiser_uuid) REFERENCES public.merchandiser(uuid);
 f   ALTER TABLE ONLY thread.order_info DROP CONSTRAINT order_info_merchandiser_uuid_merchandiser_uuid_fk;
       thread          postgres    false    280    5330    257            �           2606    19181 .   order_info order_info_party_uuid_party_uuid_fk    FK CONSTRAINT     �   ALTER TABLE ONLY thread.order_info
    ADD CONSTRAINT order_info_party_uuid_party_uuid_fk FOREIGN KEY (party_uuid) REFERENCES public.party(uuid);
 X   ALTER TABLE ONLY thread.order_info DROP CONSTRAINT order_info_party_uuid_party_uuid_fk;
       thread          postgres    false    258    280    5334            �           2606    19186 *   programs programs_created_by_users_uuid_fk    FK CONSTRAINT     �   ALTER TABLE ONLY thread.programs
    ADD CONSTRAINT programs_created_by_users_uuid_fk FOREIGN KEY (created_by) REFERENCES hr.users(uuid);
 T   ALTER TABLE ONLY thread.programs DROP CONSTRAINT programs_created_by_users_uuid_fk;
       thread          postgres    false    5290    281    238            �           2606    19191 :   programs programs_dyes_category_uuid_dyes_category_uuid_fk    FK CONSTRAINT     �   ALTER TABLE ONLY thread.programs
    ADD CONSTRAINT programs_dyes_category_uuid_dyes_category_uuid_fk FOREIGN KEY (dyes_category_uuid) REFERENCES thread.dyes_category(uuid);
 d   ALTER TABLE ONLY thread.programs DROP CONSTRAINT programs_dyes_category_uuid_dyes_category_uuid_fk;
       thread          postgres    false    5368    281    277            �           2606    19196 ,   programs programs_material_uuid_info_uuid_fk    FK CONSTRAINT     �   ALTER TABLE ONLY thread.programs
    ADD CONSTRAINT programs_material_uuid_info_uuid_fk FOREIGN KEY (material_uuid) REFERENCES material.info(uuid);
 V   ALTER TABLE ONLY thread.programs DROP CONSTRAINT programs_material_uuid_info_uuid_fk;
       thread          postgres    false    5302    281    247            �           2606    65612 $   batch batch_created_by_users_uuid_fk    FK CONSTRAINT     �   ALTER TABLE ONLY zipper.batch
    ADD CONSTRAINT batch_created_by_users_uuid_fk FOREIGN KEY (created_by) REFERENCES hr.users(uuid);
 N   ALTER TABLE ONLY zipper.batch DROP CONSTRAINT batch_created_by_users_uuid_fk;
       zipper          postgres    false    5290    282    238            �           2606    65602 0   batch_entry batch_entry_batch_uuid_batch_uuid_fk    FK CONSTRAINT     �   ALTER TABLE ONLY zipper.batch_entry
    ADD CONSTRAINT batch_entry_batch_uuid_batch_uuid_fk FOREIGN KEY (batch_uuid) REFERENCES zipper.batch(uuid);
 Z   ALTER TABLE ONLY zipper.batch_entry DROP CONSTRAINT batch_entry_batch_uuid_batch_uuid_fk;
       zipper          postgres    false    5376    283    282            �           2606    65607 ,   batch_entry batch_entry_sfg_uuid_sfg_uuid_fk    FK CONSTRAINT     �   ALTER TABLE ONLY zipper.batch_entry
    ADD CONSTRAINT batch_entry_sfg_uuid_sfg_uuid_fk FOREIGN KEY (sfg_uuid) REFERENCES zipper.sfg(uuid);
 V   ALTER TABLE ONLY zipper.batch_entry DROP CONSTRAINT batch_entry_sfg_uuid_sfg_uuid_fk;
       zipper          postgres    false    5400    283    297            �           2606    90121 (   batch batch_machine_uuid_machine_uuid_fk    FK CONSTRAINT     �   ALTER TABLE ONLY zipper.batch
    ADD CONSTRAINT batch_machine_uuid_machine_uuid_fk FOREIGN KEY (machine_uuid) REFERENCES public.machine(uuid);
 R   ALTER TABLE ONLY zipper.batch DROP CONSTRAINT batch_machine_uuid_machine_uuid_fk;
       zipper          postgres    false    305    282    5416            �           2606    19201 F   batch_production batch_production_batch_entry_uuid_batch_entry_uuid_fk    FK CONSTRAINT     �   ALTER TABLE ONLY zipper.batch_production
    ADD CONSTRAINT batch_production_batch_entry_uuid_batch_entry_uuid_fk FOREIGN KEY (batch_entry_uuid) REFERENCES zipper.batch_entry(uuid);
 p   ALTER TABLE ONLY zipper.batch_production DROP CONSTRAINT batch_production_batch_entry_uuid_batch_entry_uuid_fk;
       zipper          postgres    false    5378    285    283            �           2606    19206 :   batch_production batch_production_created_by_users_uuid_fk    FK CONSTRAINT     �   ALTER TABLE ONLY zipper.batch_production
    ADD CONSTRAINT batch_production_created_by_users_uuid_fk FOREIGN KEY (created_by) REFERENCES hr.users(uuid);
 d   ALTER TABLE ONLY zipper.batch_production DROP CONSTRAINT batch_production_created_by_users_uuid_fk;
       zipper          postgres    false    5290    285    238            �           2606    19211 D   dyed_tape_transaction dyed_tape_transaction_created_by_users_uuid_fk    FK CONSTRAINT     �   ALTER TABLE ONLY zipper.dyed_tape_transaction
    ADD CONSTRAINT dyed_tape_transaction_created_by_users_uuid_fk FOREIGN KEY (created_by) REFERENCES hr.users(uuid);
 n   ALTER TABLE ONLY zipper.dyed_tape_transaction DROP CONSTRAINT dyed_tape_transaction_created_by_users_uuid_fk;
       zipper          postgres    false    5290    286    238            �           2606    131096 Z   dyed_tape_transaction_from_stock dyed_tape_transaction_from_stock_created_by_users_uuid_fk    FK CONSTRAINT     �   ALTER TABLE ONLY zipper.dyed_tape_transaction_from_stock
    ADD CONSTRAINT dyed_tape_transaction_from_stock_created_by_users_uuid_fk FOREIGN KEY (created_by) REFERENCES hr.users(uuid);
 �   ALTER TABLE ONLY zipper.dyed_tape_transaction_from_stock DROP CONSTRAINT dyed_tape_transaction_from_stock_created_by_users_uuid_fk;
       zipper          postgres    false    238    5290    313            �           2606    131086 `   dyed_tape_transaction_from_stock dyed_tape_transaction_from_stock_order_description_uuid_order_d    FK CONSTRAINT     �   ALTER TABLE ONLY zipper.dyed_tape_transaction_from_stock
    ADD CONSTRAINT dyed_tape_transaction_from_stock_order_description_uuid_order_d FOREIGN KEY (order_description_uuid) REFERENCES zipper.order_description(uuid);
 �   ALTER TABLE ONLY zipper.dyed_tape_transaction_from_stock DROP CONSTRAINT dyed_tape_transaction_from_stock_order_description_uuid_order_d;
       zipper          postgres    false    313    291    5390            �           2606    131091 `   dyed_tape_transaction_from_stock dyed_tape_transaction_from_stock_tape_coil_uuid_tape_coil_uuid_    FK CONSTRAINT     �   ALTER TABLE ONLY zipper.dyed_tape_transaction_from_stock
    ADD CONSTRAINT dyed_tape_transaction_from_stock_tape_coil_uuid_tape_coil_uuid_ FOREIGN KEY (tape_coil_uuid) REFERENCES zipper.tape_coil(uuid);
 �   ALTER TABLE ONLY zipper.dyed_tape_transaction_from_stock DROP CONSTRAINT dyed_tape_transaction_from_stock_tape_coil_uuid_tape_coil_uuid_;
       zipper          postgres    false    313    300    5406            �           2606    19216 U   dyed_tape_transaction dyed_tape_transaction_order_description_uuid_order_description_    FK CONSTRAINT     �   ALTER TABLE ONLY zipper.dyed_tape_transaction
    ADD CONSTRAINT dyed_tape_transaction_order_description_uuid_order_description_ FOREIGN KEY (order_description_uuid) REFERENCES zipper.order_description(uuid);
    ALTER TABLE ONLY zipper.dyed_tape_transaction DROP CONSTRAINT dyed_tape_transaction_order_description_uuid_order_description_;
       zipper          postgres    false    286    291    5390            �           2606    19221 H   dying_batch_entry dying_batch_entry_batch_entry_uuid_batch_entry_uuid_fk    FK CONSTRAINT     �   ALTER TABLE ONLY zipper.dying_batch_entry
    ADD CONSTRAINT dying_batch_entry_batch_entry_uuid_batch_entry_uuid_fk FOREIGN KEY (batch_entry_uuid) REFERENCES zipper.batch_entry(uuid);
 r   ALTER TABLE ONLY zipper.dying_batch_entry DROP CONSTRAINT dying_batch_entry_batch_entry_uuid_batch_entry_uuid_fk;
       zipper          postgres    false    288    5378    283            �           2606    19226 H   dying_batch_entry dying_batch_entry_dying_batch_uuid_dying_batch_uuid_fk    FK CONSTRAINT     �   ALTER TABLE ONLY zipper.dying_batch_entry
    ADD CONSTRAINT dying_batch_entry_dying_batch_uuid_dying_batch_uuid_fk FOREIGN KEY (dying_batch_uuid) REFERENCES zipper.dying_batch(uuid);
 r   ALTER TABLE ONLY zipper.dying_batch_entry DROP CONSTRAINT dying_batch_entry_dying_batch_uuid_dying_batch_uuid_fk;
       zipper          postgres    false    288    5384    287            �           2606    19231 f   material_trx_against_order_description material_trx_against_order_description_created_by_users_uuid_fk    FK CONSTRAINT     �   ALTER TABLE ONLY zipper.material_trx_against_order_description
    ADD CONSTRAINT material_trx_against_order_description_created_by_users_uuid_fk FOREIGN KEY (created_by) REFERENCES hr.users(uuid);
 �   ALTER TABLE ONLY zipper.material_trx_against_order_description DROP CONSTRAINT material_trx_against_order_description_created_by_users_uuid_fk;
       zipper          postgres    false    238    290    5290            �           2606    19236 f   material_trx_against_order_description material_trx_against_order_description_material_uuid_info_uuid_    FK CONSTRAINT     �   ALTER TABLE ONLY zipper.material_trx_against_order_description
    ADD CONSTRAINT material_trx_against_order_description_material_uuid_info_uuid_ FOREIGN KEY (material_uuid) REFERENCES material.info(uuid);
 �   ALTER TABLE ONLY zipper.material_trx_against_order_description DROP CONSTRAINT material_trx_against_order_description_material_uuid_info_uuid_;
       zipper          postgres    false    5302    290    247            �           2606    19241 f   material_trx_against_order_description material_trx_against_order_description_order_description_uuid_o    FK CONSTRAINT     �   ALTER TABLE ONLY zipper.material_trx_against_order_description
    ADD CONSTRAINT material_trx_against_order_description_order_description_uuid_o FOREIGN KEY (order_description_uuid) REFERENCES zipper.order_description(uuid);
 �   ALTER TABLE ONLY zipper.material_trx_against_order_description DROP CONSTRAINT material_trx_against_order_description_order_description_uuid_o;
       zipper          postgres    false    5390    290    291            �           2606    19246 E   order_description order_description_bottom_stopper_properties_uuid_fk    FK CONSTRAINT     �   ALTER TABLE ONLY zipper.order_description
    ADD CONSTRAINT order_description_bottom_stopper_properties_uuid_fk FOREIGN KEY (bottom_stopper) REFERENCES public.properties(uuid);
 o   ALTER TABLE ONLY zipper.order_description DROP CONSTRAINT order_description_bottom_stopper_properties_uuid_fk;
       zipper          postgres    false    5336    291    259            �           2606    19251 D   order_description order_description_coloring_type_properties_uuid_fk    FK CONSTRAINT     �   ALTER TABLE ONLY zipper.order_description
    ADD CONSTRAINT order_description_coloring_type_properties_uuid_fk FOREIGN KEY (coloring_type) REFERENCES public.properties(uuid);
 n   ALTER TABLE ONLY zipper.order_description DROP CONSTRAINT order_description_coloring_type_properties_uuid_fk;
       zipper          postgres    false    5336    291    259            �           2606    19256 <   order_description order_description_created_by_users_uuid_fk    FK CONSTRAINT     �   ALTER TABLE ONLY zipper.order_description
    ADD CONSTRAINT order_description_created_by_users_uuid_fk FOREIGN KEY (created_by) REFERENCES hr.users(uuid);
 f   ALTER TABLE ONLY zipper.order_description DROP CONSTRAINT order_description_created_by_users_uuid_fk;
       zipper          postgres    false    5290    291    238            �           2606    19261 ?   order_description order_description_end_type_properties_uuid_fk    FK CONSTRAINT     �   ALTER TABLE ONLY zipper.order_description
    ADD CONSTRAINT order_description_end_type_properties_uuid_fk FOREIGN KEY (end_type) REFERENCES public.properties(uuid);
 i   ALTER TABLE ONLY zipper.order_description DROP CONSTRAINT order_description_end_type_properties_uuid_fk;
       zipper          postgres    false    5336    291    259            �           2606    19266 ?   order_description order_description_end_user_properties_uuid_fk    FK CONSTRAINT     �   ALTER TABLE ONLY zipper.order_description
    ADD CONSTRAINT order_description_end_user_properties_uuid_fk FOREIGN KEY (end_user) REFERENCES public.properties(uuid);
 i   ALTER TABLE ONLY zipper.order_description DROP CONSTRAINT order_description_end_user_properties_uuid_fk;
       zipper          postgres    false    5336    291    259            �           2606    19271 ;   order_description order_description_hand_properties_uuid_fk    FK CONSTRAINT     �   ALTER TABLE ONLY zipper.order_description
    ADD CONSTRAINT order_description_hand_properties_uuid_fk FOREIGN KEY (hand) REFERENCES public.properties(uuid);
 e   ALTER TABLE ONLY zipper.order_description DROP CONSTRAINT order_description_hand_properties_uuid_fk;
       zipper          postgres    false    291    5336    259            �           2606    19276 ;   order_description order_description_item_properties_uuid_fk    FK CONSTRAINT     �   ALTER TABLE ONLY zipper.order_description
    ADD CONSTRAINT order_description_item_properties_uuid_fk FOREIGN KEY (item) REFERENCES public.properties(uuid);
 e   ALTER TABLE ONLY zipper.order_description DROP CONSTRAINT order_description_item_properties_uuid_fk;
       zipper          postgres    false    291    5336    259            �           2606    19281 G   order_description order_description_light_preference_properties_uuid_fk    FK CONSTRAINT     �   ALTER TABLE ONLY zipper.order_description
    ADD CONSTRAINT order_description_light_preference_properties_uuid_fk FOREIGN KEY (light_preference) REFERENCES public.properties(uuid);
 q   ALTER TABLE ONLY zipper.order_description DROP CONSTRAINT order_description_light_preference_properties_uuid_fk;
       zipper          postgres    false    259    291    5336            �           2606    19286 @   order_description order_description_lock_type_properties_uuid_fk    FK CONSTRAINT     �   ALTER TABLE ONLY zipper.order_description
    ADD CONSTRAINT order_description_lock_type_properties_uuid_fk FOREIGN KEY (lock_type) REFERENCES public.properties(uuid);
 j   ALTER TABLE ONLY zipper.order_description DROP CONSTRAINT order_description_lock_type_properties_uuid_fk;
       zipper          postgres    false    5336    291    259            �           2606    19291 @   order_description order_description_logo_type_properties_uuid_fk    FK CONSTRAINT     �   ALTER TABLE ONLY zipper.order_description
    ADD CONSTRAINT order_description_logo_type_properties_uuid_fk FOREIGN KEY (logo_type) REFERENCES public.properties(uuid);
 j   ALTER TABLE ONLY zipper.order_description DROP CONSTRAINT order_description_logo_type_properties_uuid_fk;
       zipper          postgres    false    5336    291    259            �           2606    65536 D   order_description order_description_nylon_stopper_properties_uuid_fk    FK CONSTRAINT     �   ALTER TABLE ONLY zipper.order_description
    ADD CONSTRAINT order_description_nylon_stopper_properties_uuid_fk FOREIGN KEY (nylon_stopper) REFERENCES public.properties(uuid);
 n   ALTER TABLE ONLY zipper.order_description DROP CONSTRAINT order_description_nylon_stopper_properties_uuid_fk;
       zipper          postgres    false    259    291    5336            �           2606    19296 F   order_description order_description_order_info_uuid_order_info_uuid_fk    FK CONSTRAINT     �   ALTER TABLE ONLY zipper.order_description
    ADD CONSTRAINT order_description_order_info_uuid_order_info_uuid_fk FOREIGN KEY (order_info_uuid) REFERENCES zipper.order_info(uuid);
 p   ALTER TABLE ONLY zipper.order_description DROP CONSTRAINT order_description_order_info_uuid_order_info_uuid_fk;
       zipper          postgres    false    5394    291    294            �           2606    19301 C   order_description order_description_puller_color_properties_uuid_fk    FK CONSTRAINT     �   ALTER TABLE ONLY zipper.order_description
    ADD CONSTRAINT order_description_puller_color_properties_uuid_fk FOREIGN KEY (puller_color) REFERENCES public.properties(uuid);
 m   ALTER TABLE ONLY zipper.order_description DROP CONSTRAINT order_description_puller_color_properties_uuid_fk;
       zipper          postgres    false    5336    291    259            �           2606    19311 B   order_description order_description_puller_type_properties_uuid_fk    FK CONSTRAINT     �   ALTER TABLE ONLY zipper.order_description
    ADD CONSTRAINT order_description_puller_type_properties_uuid_fk FOREIGN KEY (puller_type) REFERENCES public.properties(uuid);
 l   ALTER TABLE ONLY zipper.order_description DROP CONSTRAINT order_description_puller_type_properties_uuid_fk;
       zipper          postgres    false    5336    291    259            �           2606    19316 H   order_description order_description_slider_body_shape_properties_uuid_fk    FK CONSTRAINT     �   ALTER TABLE ONLY zipper.order_description
    ADD CONSTRAINT order_description_slider_body_shape_properties_uuid_fk FOREIGN KEY (slider_body_shape) REFERENCES public.properties(uuid);
 r   ALTER TABLE ONLY zipper.order_description DROP CONSTRAINT order_description_slider_body_shape_properties_uuid_fk;
       zipper          postgres    false    5336    291    259            �           2606    19321 B   order_description order_description_slider_link_properties_uuid_fk    FK CONSTRAINT     �   ALTER TABLE ONLY zipper.order_description
    ADD CONSTRAINT order_description_slider_link_properties_uuid_fk FOREIGN KEY (slider_link) REFERENCES public.properties(uuid);
 l   ALTER TABLE ONLY zipper.order_description DROP CONSTRAINT order_description_slider_link_properties_uuid_fk;
       zipper          postgres    false    259    5336    291            �           2606    19326 =   order_description order_description_slider_properties_uuid_fk    FK CONSTRAINT     �   ALTER TABLE ONLY zipper.order_description
    ADD CONSTRAINT order_description_slider_properties_uuid_fk FOREIGN KEY (slider) REFERENCES public.properties(uuid);
 g   ALTER TABLE ONLY zipper.order_description DROP CONSTRAINT order_description_slider_properties_uuid_fk;
       zipper          postgres    false    259    291    5336            �           2606    65552 D   order_description order_description_tape_coil_uuid_tape_coil_uuid_fk    FK CONSTRAINT     �   ALTER TABLE ONLY zipper.order_description
    ADD CONSTRAINT order_description_tape_coil_uuid_tape_coil_uuid_fk FOREIGN KEY (tape_coil_uuid) REFERENCES zipper.tape_coil(uuid);
 n   ALTER TABLE ONLY zipper.order_description DROP CONSTRAINT order_description_tape_coil_uuid_tape_coil_uuid_fk;
       zipper          postgres    false    300    291    5406            �           2606    19331 B   order_description order_description_teeth_color_properties_uuid_fk    FK CONSTRAINT     �   ALTER TABLE ONLY zipper.order_description
    ADD CONSTRAINT order_description_teeth_color_properties_uuid_fk FOREIGN KEY (teeth_color) REFERENCES public.properties(uuid);
 l   ALTER TABLE ONLY zipper.order_description DROP CONSTRAINT order_description_teeth_color_properties_uuid_fk;
       zipper          postgres    false    291    5336    259            �           2606    73729 A   order_description order_description_teeth_type_properties_uuid_fk    FK CONSTRAINT     �   ALTER TABLE ONLY zipper.order_description
    ADD CONSTRAINT order_description_teeth_type_properties_uuid_fk FOREIGN KEY (teeth_type) REFERENCES public.properties(uuid);
 k   ALTER TABLE ONLY zipper.order_description DROP CONSTRAINT order_description_teeth_type_properties_uuid_fk;
       zipper          postgres    false    291    259    5336            �           2606    19336 B   order_description order_description_top_stopper_properties_uuid_fk    FK CONSTRAINT     �   ALTER TABLE ONLY zipper.order_description
    ADD CONSTRAINT order_description_top_stopper_properties_uuid_fk FOREIGN KEY (top_stopper) REFERENCES public.properties(uuid);
 l   ALTER TABLE ONLY zipper.order_description DROP CONSTRAINT order_description_top_stopper_properties_uuid_fk;
       zipper          postgres    false    259    291    5336            �           2606    19341 D   order_description order_description_zipper_number_properties_uuid_fk    FK CONSTRAINT     �   ALTER TABLE ONLY zipper.order_description
    ADD CONSTRAINT order_description_zipper_number_properties_uuid_fk FOREIGN KEY (zipper_number) REFERENCES public.properties(uuid);
 n   ALTER TABLE ONLY zipper.order_description DROP CONSTRAINT order_description_zipper_number_properties_uuid_fk;
       zipper          postgres    false    5336    291    259            �           2606    19346 H   order_entry order_entry_order_description_uuid_order_description_uuid_fk    FK CONSTRAINT     �   ALTER TABLE ONLY zipper.order_entry
    ADD CONSTRAINT order_entry_order_description_uuid_order_description_uuid_fk FOREIGN KEY (order_description_uuid) REFERENCES zipper.order_description(uuid);
 r   ALTER TABLE ONLY zipper.order_entry DROP CONSTRAINT order_entry_order_description_uuid_order_description_uuid_fk;
       zipper          postgres    false    5390    292    291            �           2606    19351 .   order_info order_info_buyer_uuid_buyer_uuid_fk    FK CONSTRAINT     �   ALTER TABLE ONLY zipper.order_info
    ADD CONSTRAINT order_info_buyer_uuid_buyer_uuid_fk FOREIGN KEY (buyer_uuid) REFERENCES public.buyer(uuid);
 X   ALTER TABLE ONLY zipper.order_info DROP CONSTRAINT order_info_buyer_uuid_buyer_uuid_fk;
       zipper          postgres    false    5318    294    254            �           2606    19356 2   order_info order_info_factory_uuid_factory_uuid_fk    FK CONSTRAINT     �   ALTER TABLE ONLY zipper.order_info
    ADD CONSTRAINT order_info_factory_uuid_factory_uuid_fk FOREIGN KEY (factory_uuid) REFERENCES public.factory(uuid);
 \   ALTER TABLE ONLY zipper.order_info DROP CONSTRAINT order_info_factory_uuid_factory_uuid_fk;
       zipper          postgres    false    5322    294    255            �           2606    19361 6   order_info order_info_marketing_uuid_marketing_uuid_fk    FK CONSTRAINT     �   ALTER TABLE ONLY zipper.order_info
    ADD CONSTRAINT order_info_marketing_uuid_marketing_uuid_fk FOREIGN KEY (marketing_uuid) REFERENCES public.marketing(uuid);
 `   ALTER TABLE ONLY zipper.order_info DROP CONSTRAINT order_info_marketing_uuid_marketing_uuid_fk;
       zipper          postgres    false    5326    294    256            �           2606    19366 <   order_info order_info_merchandiser_uuid_merchandiser_uuid_fk    FK CONSTRAINT     �   ALTER TABLE ONLY zipper.order_info
    ADD CONSTRAINT order_info_merchandiser_uuid_merchandiser_uuid_fk FOREIGN KEY (merchandiser_uuid) REFERENCES public.merchandiser(uuid);
 f   ALTER TABLE ONLY zipper.order_info DROP CONSTRAINT order_info_merchandiser_uuid_merchandiser_uuid_fk;
       zipper          postgres    false    5330    294    257            �           2606    19371 .   order_info order_info_party_uuid_party_uuid_fk    FK CONSTRAINT     �   ALTER TABLE ONLY zipper.order_info
    ADD CONSTRAINT order_info_party_uuid_party_uuid_fk FOREIGN KEY (party_uuid) REFERENCES public.party(uuid);
 X   ALTER TABLE ONLY zipper.order_info DROP CONSTRAINT order_info_party_uuid_party_uuid_fk;
       zipper          postgres    false    5334    294    258            �           2606    19376 *   planning planning_created_by_users_uuid_fk    FK CONSTRAINT     �   ALTER TABLE ONLY zipper.planning
    ADD CONSTRAINT planning_created_by_users_uuid_fk FOREIGN KEY (created_by) REFERENCES hr.users(uuid);
 T   ALTER TABLE ONLY zipper.planning DROP CONSTRAINT planning_created_by_users_uuid_fk;
       zipper          postgres    false    295    5290    238            �           2606    19381 <   planning_entry planning_entry_planning_week_planning_week_fk    FK CONSTRAINT     �   ALTER TABLE ONLY zipper.planning_entry
    ADD CONSTRAINT planning_entry_planning_week_planning_week_fk FOREIGN KEY (planning_week) REFERENCES zipper.planning(week);
 f   ALTER TABLE ONLY zipper.planning_entry DROP CONSTRAINT planning_entry_planning_week_planning_week_fk;
       zipper          postgres    false    296    5396    295            �           2606    19386 2   planning_entry planning_entry_sfg_uuid_sfg_uuid_fk    FK CONSTRAINT     �   ALTER TABLE ONLY zipper.planning_entry
    ADD CONSTRAINT planning_entry_sfg_uuid_sfg_uuid_fk FOREIGN KEY (sfg_uuid) REFERENCES zipper.sfg(uuid);
 \   ALTER TABLE ONLY zipper.planning_entry DROP CONSTRAINT planning_entry_sfg_uuid_sfg_uuid_fk;
       zipper          postgres    false    297    296    5400            �           2606    19391 ,   sfg sfg_order_entry_uuid_order_entry_uuid_fk    FK CONSTRAINT     �   ALTER TABLE ONLY zipper.sfg
    ADD CONSTRAINT sfg_order_entry_uuid_order_entry_uuid_fk FOREIGN KEY (order_entry_uuid) REFERENCES zipper.order_entry(uuid);
 V   ALTER TABLE ONLY zipper.sfg DROP CONSTRAINT sfg_order_entry_uuid_order_entry_uuid_fk;
       zipper          postgres    false    5392    297    292            �           2606    19396 6   sfg_production sfg_production_created_by_users_uuid_fk    FK CONSTRAINT     �   ALTER TABLE ONLY zipper.sfg_production
    ADD CONSTRAINT sfg_production_created_by_users_uuid_fk FOREIGN KEY (created_by) REFERENCES hr.users(uuid);
 `   ALTER TABLE ONLY zipper.sfg_production DROP CONSTRAINT sfg_production_created_by_users_uuid_fk;
       zipper          postgres    false    5290    298    238            �           2606    19401 2   sfg_production sfg_production_sfg_uuid_sfg_uuid_fk    FK CONSTRAINT     �   ALTER TABLE ONLY zipper.sfg_production
    ADD CONSTRAINT sfg_production_sfg_uuid_sfg_uuid_fk FOREIGN KEY (sfg_uuid) REFERENCES zipper.sfg(uuid);
 \   ALTER TABLE ONLY zipper.sfg_production DROP CONSTRAINT sfg_production_sfg_uuid_sfg_uuid_fk;
       zipper          postgres    false    5400    298    297            �           2606    19406 "   sfg sfg_recipe_uuid_recipe_uuid_fk    FK CONSTRAINT     �   ALTER TABLE ONLY zipper.sfg
    ADD CONSTRAINT sfg_recipe_uuid_recipe_uuid_fk FOREIGN KEY (recipe_uuid) REFERENCES lab_dip.recipe(uuid);
 L   ALTER TABLE ONLY zipper.sfg DROP CONSTRAINT sfg_recipe_uuid_recipe_uuid_fk;
       zipper          postgres    false    5294    297    241            �           2606    19411 8   sfg_transaction sfg_transaction_created_by_users_uuid_fk    FK CONSTRAINT     �   ALTER TABLE ONLY zipper.sfg_transaction
    ADD CONSTRAINT sfg_transaction_created_by_users_uuid_fk FOREIGN KEY (created_by) REFERENCES hr.users(uuid);
 b   ALTER TABLE ONLY zipper.sfg_transaction DROP CONSTRAINT sfg_transaction_created_by_users_uuid_fk;
       zipper          postgres    false    5290    299    238            �           2606    19416 4   sfg_transaction sfg_transaction_sfg_uuid_sfg_uuid_fk    FK CONSTRAINT     �   ALTER TABLE ONLY zipper.sfg_transaction
    ADD CONSTRAINT sfg_transaction_sfg_uuid_sfg_uuid_fk FOREIGN KEY (sfg_uuid) REFERENCES zipper.sfg(uuid);
 ^   ALTER TABLE ONLY zipper.sfg_transaction DROP CONSTRAINT sfg_transaction_sfg_uuid_sfg_uuid_fk;
       zipper          postgres    false    5400    299    297            �           2606    19421 >   sfg_transaction sfg_transaction_slider_item_uuid_stock_uuid_fk    FK CONSTRAINT     �   ALTER TABLE ONLY zipper.sfg_transaction
    ADD CONSTRAINT sfg_transaction_slider_item_uuid_stock_uuid_fk FOREIGN KEY (slider_item_uuid) REFERENCES slider.stock(uuid);
 h   ALTER TABLE ONLY zipper.sfg_transaction DROP CONSTRAINT sfg_transaction_slider_item_uuid_stock_uuid_fk;
       zipper          postgres    false    299    270    5356            �           2606    32790 ,   tape_coil tape_coil_created_by_users_uuid_fk    FK CONSTRAINT     �   ALTER TABLE ONLY zipper.tape_coil
    ADD CONSTRAINT tape_coil_created_by_users_uuid_fk FOREIGN KEY (created_by) REFERENCES hr.users(uuid);
 V   ALTER TABLE ONLY zipper.tape_coil DROP CONSTRAINT tape_coil_created_by_users_uuid_fk;
       zipper          postgres    false    5290    300    238            �           2606    32780 0   tape_coil tape_coil_item_uuid_properties_uuid_fk    FK CONSTRAINT     �   ALTER TABLE ONLY zipper.tape_coil
    ADD CONSTRAINT tape_coil_item_uuid_properties_uuid_fk FOREIGN KEY (item_uuid) REFERENCES public.properties(uuid);
 Z   ALTER TABLE ONLY zipper.tape_coil DROP CONSTRAINT tape_coil_item_uuid_properties_uuid_fk;
       zipper          postgres    false    5336    300    259            �           2606    19426 B   tape_coil_production tape_coil_production_created_by_users_uuid_fk    FK CONSTRAINT     �   ALTER TABLE ONLY zipper.tape_coil_production
    ADD CONSTRAINT tape_coil_production_created_by_users_uuid_fk FOREIGN KEY (created_by) REFERENCES hr.users(uuid);
 l   ALTER TABLE ONLY zipper.tape_coil_production DROP CONSTRAINT tape_coil_production_created_by_users_uuid_fk;
       zipper          postgres    false    238    301    5290            �           2606    19431 J   tape_coil_production tape_coil_production_tape_coil_uuid_tape_coil_uuid_fk    FK CONSTRAINT     �   ALTER TABLE ONLY zipper.tape_coil_production
    ADD CONSTRAINT tape_coil_production_tape_coil_uuid_tape_coil_uuid_fk FOREIGN KEY (tape_coil_uuid) REFERENCES zipper.tape_coil(uuid);
 t   ALTER TABLE ONLY zipper.tape_coil_production DROP CONSTRAINT tape_coil_production_tape_coil_uuid_tape_coil_uuid_fk;
       zipper          postgres    false    301    5406    300            �           2606    65597 >   tape_coil_required tape_coil_required_created_by_users_uuid_fk    FK CONSTRAINT     �   ALTER TABLE ONLY zipper.tape_coil_required
    ADD CONSTRAINT tape_coil_required_created_by_users_uuid_fk FOREIGN KEY (created_by) REFERENCES hr.users(uuid);
 h   ALTER TABLE ONLY zipper.tape_coil_required DROP CONSTRAINT tape_coil_required_created_by_users_uuid_fk;
       zipper          postgres    false    5290    304    238            �           2606    65577 F   tape_coil_required tape_coil_required_end_type_uuid_properties_uuid_fk    FK CONSTRAINT     �   ALTER TABLE ONLY zipper.tape_coil_required
    ADD CONSTRAINT tape_coil_required_end_type_uuid_properties_uuid_fk FOREIGN KEY (end_type_uuid) REFERENCES public.properties(uuid);
 p   ALTER TABLE ONLY zipper.tape_coil_required DROP CONSTRAINT tape_coil_required_end_type_uuid_properties_uuid_fk;
       zipper          postgres    false    259    304    5336            �           2606    65582 B   tape_coil_required tape_coil_required_item_uuid_properties_uuid_fk    FK CONSTRAINT     �   ALTER TABLE ONLY zipper.tape_coil_required
    ADD CONSTRAINT tape_coil_required_item_uuid_properties_uuid_fk FOREIGN KEY (item_uuid) REFERENCES public.properties(uuid);
 l   ALTER TABLE ONLY zipper.tape_coil_required DROP CONSTRAINT tape_coil_required_item_uuid_properties_uuid_fk;
       zipper          postgres    false    5336    304    259            �           2606    65587 K   tape_coil_required tape_coil_required_nylon_stopper_uuid_properties_uuid_fk    FK CONSTRAINT     �   ALTER TABLE ONLY zipper.tape_coil_required
    ADD CONSTRAINT tape_coil_required_nylon_stopper_uuid_properties_uuid_fk FOREIGN KEY (nylon_stopper_uuid) REFERENCES public.properties(uuid);
 u   ALTER TABLE ONLY zipper.tape_coil_required DROP CONSTRAINT tape_coil_required_nylon_stopper_uuid_properties_uuid_fk;
       zipper          postgres    false    5336    304    259            �           2606    65592 K   tape_coil_required tape_coil_required_zipper_number_uuid_properties_uuid_fk    FK CONSTRAINT     �   ALTER TABLE ONLY zipper.tape_coil_required
    ADD CONSTRAINT tape_coil_required_zipper_number_uuid_properties_uuid_fk FOREIGN KEY (zipper_number_uuid) REFERENCES public.properties(uuid);
 u   ALTER TABLE ONLY zipper.tape_coil_required DROP CONSTRAINT tape_coil_required_zipper_number_uuid_properties_uuid_fk;
       zipper          postgres    false    5336    304    259            �           2606    19436 @   tape_coil_to_dyeing tape_coil_to_dyeing_created_by_users_uuid_fk    FK CONSTRAINT     �   ALTER TABLE ONLY zipper.tape_coil_to_dyeing
    ADD CONSTRAINT tape_coil_to_dyeing_created_by_users_uuid_fk FOREIGN KEY (created_by) REFERENCES hr.users(uuid);
 j   ALTER TABLE ONLY zipper.tape_coil_to_dyeing DROP CONSTRAINT tape_coil_to_dyeing_created_by_users_uuid_fk;
       zipper          postgres    false    238    302    5290            �           2606    19441 S   tape_coil_to_dyeing tape_coil_to_dyeing_order_description_uuid_order_description_uu    FK CONSTRAINT     �   ALTER TABLE ONLY zipper.tape_coil_to_dyeing
    ADD CONSTRAINT tape_coil_to_dyeing_order_description_uuid_order_description_uu FOREIGN KEY (order_description_uuid) REFERENCES zipper.order_description(uuid);
 }   ALTER TABLE ONLY zipper.tape_coil_to_dyeing DROP CONSTRAINT tape_coil_to_dyeing_order_description_uuid_order_description_uu;
       zipper          postgres    false    5390    302    291            �           2606    19446 H   tape_coil_to_dyeing tape_coil_to_dyeing_tape_coil_uuid_tape_coil_uuid_fk    FK CONSTRAINT     �   ALTER TABLE ONLY zipper.tape_coil_to_dyeing
    ADD CONSTRAINT tape_coil_to_dyeing_tape_coil_uuid_tape_coil_uuid_fk FOREIGN KEY (tape_coil_uuid) REFERENCES zipper.tape_coil(uuid);
 r   ALTER TABLE ONLY zipper.tape_coil_to_dyeing DROP CONSTRAINT tape_coil_to_dyeing_tape_coil_uuid_tape_coil_uuid_fk;
       zipper          postgres    false    5406    302    300            �           2606    32785 9   tape_coil tape_coil_zipper_number_uuid_properties_uuid_fk    FK CONSTRAINT     �   ALTER TABLE ONLY zipper.tape_coil
    ADD CONSTRAINT tape_coil_zipper_number_uuid_properties_uuid_fk FOREIGN KEY (zipper_number_uuid) REFERENCES public.properties(uuid);
 c   ALTER TABLE ONLY zipper.tape_coil DROP CONSTRAINT tape_coil_zipper_number_uuid_properties_uuid_fk;
       zipper          postgres    false    5336    300    259            �           2606    19451 .   tape_trx tape_to_coil_created_by_users_uuid_fk    FK CONSTRAINT     �   ALTER TABLE ONLY zipper.tape_trx
    ADD CONSTRAINT tape_to_coil_created_by_users_uuid_fk FOREIGN KEY (created_by) REFERENCES hr.users(uuid);
 X   ALTER TABLE ONLY zipper.tape_trx DROP CONSTRAINT tape_to_coil_created_by_users_uuid_fk;
       zipper          postgres    false    5290    303    238            �           2606    19456 6   tape_trx tape_to_coil_tape_coil_uuid_tape_coil_uuid_fk    FK CONSTRAINT     �   ALTER TABLE ONLY zipper.tape_trx
    ADD CONSTRAINT tape_to_coil_tape_coil_uuid_tape_coil_uuid_fk FOREIGN KEY (tape_coil_uuid) REFERENCES zipper.tape_coil(uuid);
 `   ALTER TABLE ONLY zipper.tape_trx DROP CONSTRAINT tape_to_coil_tape_coil_uuid_tape_coil_uuid_fk;
       zipper          postgres    false    5406    303    300            �           2606    81932 *   tape_trx tape_trx_created_by_users_uuid_fk    FK CONSTRAINT     �   ALTER TABLE ONLY zipper.tape_trx
    ADD CONSTRAINT tape_trx_created_by_users_uuid_fk FOREIGN KEY (created_by) REFERENCES hr.users(uuid);
 T   ALTER TABLE ONLY zipper.tape_trx DROP CONSTRAINT tape_trx_created_by_users_uuid_fk;
       zipper          postgres    false    5290    303    238            �           2606    81927 2   tape_trx tape_trx_tape_coil_uuid_tape_coil_uuid_fk    FK CONSTRAINT     �   ALTER TABLE ONLY zipper.tape_trx
    ADD CONSTRAINT tape_trx_tape_coil_uuid_tape_coil_uuid_fk FOREIGN KEY (tape_coil_uuid) REFERENCES zipper.tape_coil(uuid);
 \   ALTER TABLE ONLY zipper.tape_trx DROP CONSTRAINT tape_trx_tape_coil_uuid_tape_coil_uuid_fk;
       zipper          postgres    false    300    5406    303            �   �  x�]S_o�0���>ю@�%}��Ut�Q�n��T�!.���&@?��N`]�<�/w�?�s{_<��@����������(7A���/���0�
�M�+L]�m�P�d�&V�0�5�`�O.d�OQ'h���y���Aŭ^]�i0g9ꍁ�y<�]�U�	�����ߛ��~����n/
[���+����e����I�������rQ{�(��1��3ick�J��R0x�zh�D�ZT�!Ń�י.���r���=�ַ�$Ψ�2�e<�`ǅ���%�DɄ�,n�fT�$�X�N�'D%�a!�2^T�~q�*�Ӫ���}���Tj帯?��P[���v,��)[+��xN�a���v�5u?����j$1ܨ�i2�<���������6n�uT�'��Sy�VJ���8P(��*4.���H4_�c�t�MP0-���,q�B�i�p�0����~��j?[�@�%r�fK�5�W���`y�'uܒ�L:?訉���	/#Z��@K�֒���0ӊT�H"K�I!y�3��ĵ�4�%��gX���*�&,���D�S�.�L�eVL�unB��Ɯ����ӗ����h���i�q�I[��)��-��hc�f���LUU���Tק�!��[�8�:�h��0�^�a/@��	F��c�q�6��o�� �v�WQ���h4�ώ�      �      x�p7
*	/���O�4/�4wO�33p��Lγ(.�4�4202�54�5�P00�#N= ���C�T J @��Ĝ�Tǀӻ*#��74���=�;�b��������������T�!� �=... �%�      9   [  x���]s�0��ïp�n;	������(-���.�|i}����vf����;�7'3�yrN���Cf��iD�a��	�U�K�X���Ϻݽ�� E،IM��ћ����U��!d� 0��J����9ܷ{��I�X;�#��'��K��Ч�}�~�Fֶ� A��v Զ����ȱj�l#�;u�W i|�[��@(",�����B"�%)�_w<t�e.�q�T����ݛ�)�X3���e����`zo�R+1�,|֕�����Sǯ���̝N] 7���V��e��@��Ċ�9N�@)֙T���~Z����Z�:�M+\�X^d�'�!1�x�T�UX�w�Jry�l<�d�,v��ހ�ؚ���Yɟ����J F��goU���!+��h���?!�8��r��D̈�$,��@7z�*����/5N� K��r���pO6\٢
PC�@n~����%��Wz~sx����qI0z�/�7���
יf�6y��o@���t��,�e.`�Wo ���y�7"�y�3�6�-��^N}�*��k91�������7)u�q�%.&!A��q���"�`��ܵ#��޵P�wE� �i?
      :   �  x����r�0�kx
_��$�Cr�DP� �ވ���"ا/�ݙ���E��՚����'��ul�pV� �2Z\U�j���am�6��P�A<�w���+h� �/�� � ��b��QN`ލ��b�#=v�a3l����� �y�i��	�-So��a/k/17h�V���U� By�1M.˄D!��p�n�zw���������>Qϙ9����J�).����Ʋ�t5L���q�!E�ߡ�0ڎ�}��$E�:L�����ϱ�Jc��̝BzP�<G��u�渟����������/��]9���S���ٰ��@>h~����#���̏(�)E��%�JV��>cW0���M��7&�GoQ�4�8T8/e�}�c]2!W�m��l���"�m��;2-�Z~p�*�Ɇ^�Q ]oĳf�=/&�+��\��:�D�1��¬*�"]�e��-���)$����_�����J#M��Ɋ�F���ZYOf�$�;��	��3D(Hnf��X���ƾ��,�	y��      �   R  x����n�@������~�7S,X���1^,DQ�BQ���=�h��d�����f=��3�;E��!�{����V�/��ءz�U�/�DX��T�2�皩b]0&�	U�����<r�z0��*��?�W-�϶c��8_��ؿ��?)��k\�Tp&8�4�1ꄥ�E�������`��`X�8��N5�Z���mV%�	2V����\�$QA��&;HƳd��k��캃�%��sb��̫�e�/@ڂf.-F�I��y+����%Ǆ	���N�X��1���Vʒ�S��e�(0���l���0�.v<L��+f z8~R����      �   0  x����n�@ ��5<�/`3����B����q#0�e
�:<��i�4���/'g��p��q]3Nc*��f�x�ݳT
q�7��qWY��\@�z�=	20d�OS�$+O��AK�l�^�#�m�<�V^{�U��w�NXhH݈ܱ������I�ݿ�w�٨�	�����Z Q�xm�й@�h|R���]%�'acCV��K.V���%,���.��j'!1�NvW�i���b���'��n���;�:4�u5nQ�,8]n�Fz>��p�A0PPv�ʙ��%L�Y�p��i�$���<�      �   P  x����n�@������܁�a�(�Ļq#0���R*Oߑ.�8�69�����U�[}�vF�� ��x����}����1�C��Iq��`�*cD0T������I�/�0��9�	���O��9h��p�,��nV��"&���L{�L��!S" �d�EP��b}����֯���?+���&�2U�9��ϥ+i�/�fܒ��x��-/����.L�Hiט�N�y��wa���c�����n5�cjN�4��q2������v��W�z!�@������j��p��G��e	Ʈ3�����RmU��y0��)�      �   �  x����N�@E����js��ۂ��!��K���Em�^4MK����kg�3��{�������w(Z�UwSG|��%��8_ǚe�����
p�C0�@��ɕ�Ƃ�3��t�4F�@ј��R�)#�`��dD��f�^j�Nv�a-M �g�J�oL�(��_o��M���}��6��:��Z0��~x~��{��{NԬ��"QW�N�D,,���?ӳ���/�ǓK�͹9<����Xᤚ%��.\q[X] �w�U�W�������G���ո
s0������ �ع����R�evjiP� c��0��rl"�XfVh�k���;��Ϧ��F��3sj�=s��o̻0���Us�
֎�Ҳj~5�<]+����|      �      x�=�Y�$+E���!���a���QDd�uW��A��x�G�J��^���F:늯�NK��l}�u�)֓�1s�2��5�z���y���GL�X�{��\�:��}��&j7�>;�R�]�m����m�bg�Q?UZkՋ���\��i�N���ʙ��d�Cg/��^�(�[����.?ѩ�}|
��"V�����6v�V�������;��Қ�����!�vV�{�9��ö?-i-]�������6&Y=J$g_1��9����I�픑2?��K*����+�ܲ���g8͟��R�W}nk�j���4t�5���;i���FK���_��k��^{������8��Es�(���ї�cV_�v�F�9��9��7?�-�K(Z���4�G s�vm>�,2'�t���lf>��s��
$n4AogϿ�=G+���Fɖ
�_c� �����h�w��){M�ҩ�5����ZXU]%
�M�8�7��I�lKo���vZ{�$i �=r|�R��J:V������*zKE%����r��4�U�`���t���]6�X��rv>]���_��h�W1{}syz�)�3}z��mz 8� �RR[�^�d[i[���m4�rp��ȿ�5�^�,ϩ�4�4�%�k��*�vҜ>l��y��)���mj^U��a�ǿ�-5���	b�|�䤽�,@�#�R���c���T�6�� �Cov��ZSnkԇC���p�s��7�ơiu[>wr0�3U�-�:�-��h�#v{s{X����2aKj�'C͸F��UfY,~�'�~��r.��Y��V���������D1��ɮ�E�SO��&0�bTN~ng̀?�`D $�]{�ebr��5�4���,�S<�K����M�V5��8��g���s�o�A3Lay�?B�٤1��Ȧ
���i�c��Uꨧ�#��y�9�t|��O�UԜ�ܝ ���}�2G����a�|Wʧ ���͘��j�	t��蟊�q�]ߒ��/TY�d�z���O9���D���?����J�şu�n�-�a!�N���n��3�[�����z}^��=��Uy����ؽ�[գ����Sh!(�&��Z�Ƹ�%�T9�of~�-u��d��r�x�U�Ϯ�c}V:SD�܅�ѐ�'�;s���0�l (��3�4�aW�E�[��'���1���aEc18Ɣ���)�P���RwamC����Ѷ��\O���`�l)��=L��٧QC�jKkU���<�#MH�BX�s=-�uO��;k5zl�R��Y�\��9C�􅢏��>TC�Fc��Ԛ�o2���Ul���φ��̨��'�<o��`h6�Ԁ�B�K@Aw-Yo��Zߊ�d�ǟ�W��FX�������E�v�-X��r��qp��A=9�=ӯ"l��3����Nk#NL�����9�� =���p�<

����u�)XB�J~0[NI~K0F��wL�B���W��K=�C�3�]�U귏�îkz!#<�_�.�ey���ZuI��[���F
^��AG��3i��+S�z�h�hW���+.j��`2_/3����s�(���_Ŏ���_��.�\�����ٱՂda;S�7��r�"O�fH0�	9�L�lP������&ZQ$߹����P,\�pl�m�΋ca�8�r��9���U�R��c{Bb8ܭa����`���|�-kXAK����s����U��X�3�6��@2��'7�������AqZ]X6\Ӈs���vj?���$z���c��1<L�7�VǔU��cF`j�,`�/����e�����%r�?f��)=1cơjӃKf�#W��k�����������f�����Y����_,w2S��j�a�nt�i[�S8�΃�V,8��5?D���r<g��u�\w(aa�|Q�����:�~bj�V,h��[˃��#�Q� �ź�8m�����c����x2Ft�N��m&����n�S��!��_-��F�;cc�?jTW��l10�@t.�#zlz �_����Z�������Yl"y�[m9CAP�B5�7��7�Ό�G}��<s�a�ߪϾ��r����=���q+�IF�����
��%���_E4C���d$�H"�'�MH	�y^�'pY�]]8�3��c�q=W�*B��j���1�l�g��`2��G�`�2$(T2��/ |��T����'T��AX>�.�A`x$���|�5l�B1%��������O�*Z�#�!�8��UN�~E�q-����	���o\2҈3�R �x��X%�z�<�N�H��
��5a.	8�p�'-,#�3��;җ����У��j~z�Xq��*����g���Nar����Q�Xs@�n���ߙ�$a�(�r������@�sT�ɌHQ2�MVE"/�����M'�+�op��M�u*�3#����z�݀�O��(L�>�(��m��CX.ޯ �z,�^"�+2I� -�~��X�@o8��7�F�^Y��>q��Ø7�3��1��Z���#��*�����}㪘	�a!��4�a9%�|��PC]�u~FN�����}H8���$�0��u`^ȉn���g�(��L8:���w
+Y<$�]�3�h�m��t���;p��� A,b�+܍���}0�~+���q\��g2)?�P l�7�$=���bg�3t�<y��}R��4�~��`s����̉��!6�6����/bu���u3#��:i�W��Y'B���� �%�]1�8��GX����vZXA����Ed>���Fd�䟸��=�����7��J��+�=���rK�e�%UpĄ�Is�cpڷ"�9�����i��X!
%�\:d�	\+�)�hX\  ��C���k��s��O�����/&c�Z?!�^�[;�$���nߊ)f�!BX�֌��G���U����O�j�a���k�3��MN��ՆW$��=ޛ�P���`�-a��LH<'�O�$ݒ1��l>.6}�Q/�r�,�$ws4�Ȁ�lam�_a�H���E%��Sxi���m���&�X��
�J�Ģ�kHN����5���3��%�%��L֕SÊ�0-K��Yp�k�
��:�b���a�n�lu�o�n{��m�Y�d���f��%�X�<S��^ ��9h�m(n�W�Sg
1k����ʐ���$�@�	k�aCu����T,L���q�8q2��S�l��0�%�^w��d �4r%��{����<����C�lp2���L�b����˅D0� vƵ31�|�p8FYi��1w"��v���󫨟۽���.e��E!�T��;�@R��EfZ��@C����]K
Op{M�>j�If�p��q��MT�x�1�`���Q>�`��L����,�dR�XAO�8	��Nf�h5���C�(n���l[x�z&��὘n�����q{�>ZK��y�
8����x5�f%��I��[%gV؃�V�س���q��t�4���iln8��_��+��d�9$�1E@b�J���`e`1]qY�"μ�	YB�/����i#�lf��C�^�r�(!�誱��w ���jǇ[�Bz�M
�w��(����:YY2���n�����GC�>�E�!<$N�q�D1���>��H�	@, �sG���;�0�I� ���3q��ك.ގ7�;�f��CE�7�L���%��fFK��Ж�<�"#�o�iL*N�~�!~�<D��h@�d2;1K	�V�4|���R��x�6�覿�!°YGg@A�K��Vc����#f����*�!a�q����Y�庿]ׂ�k���cqO9�*��48}���_`�6fDNd�d�l���w�ׯ"Ύm���p�q�!.�Ӧ��BGW�om	���A���yl��G�7��z�̮����.��j�UA�����JY��L�ؓ.����R��؂"���C��mw���V�ߘ�퉇fP��qϊ����Z�	 �l 8�C�'(�8�7).[��\�`as����Jx祽��#>5̀�h����7����L�m�{�D��b@������H6p��2s��Ղb�7��V�������zy��q���M����q�I Q  [�� �aJ�W��Y1]d�4���~g�4>��YēQ��+d�f�3��G�.�l�t�������)P�pd��of,gX�̅YC/q�x����"a��%DV�k<΋� ^2*�)�ү�F��B5��0��z�	ESМ`�
���1�)':*ȡ'�5q�[�����=7���d$5�������Y@��?��2E��>�W���U,�����\X`y�������F�p��*و%���3��)��[�_�x-��d`\2Վ�P�kg	,��#��0bʹ90�|�j��)"�aH���q���
��	�ɞ"�|����	y��JJds��.`�OE�����7�2X�E$���'$8�&�p����� ,&?e�c�.nl}!��@������6� \��d9Ƹ�V<�>�&����B7.���c�*O���h���vѬ',�g-���irXz@2-W&��?X��N���;�O��I�$���Y+%������q���ƦMB!��0�7s�/$�t��9����$��a��5.+$^Ņ���ղ��2膿�#�"�d�"�3�p)"O�w|�+�q�(@�|�,��<Jʏ��L4[�� �`�z�F���|�d[�O|@�܎���Ir������G��n�Cw|r�	���Ӆ�ixg��Y�2�-)�W�� �=Ò��O4���Js9�z��A����n�M��c�����%��D�FIb1n8�	3`���|7]x+}*	 �T�@+�1��K�م����?�:�-����y�h�pw�%Κ���B@���(I���Y��Vg�9.`�㐍<���$XN$]I�\ص��BhG�_#��J2����d�_ܱ�Ąѱ�7^q�񾻇���0|�>�#^Q��A�X���;�$��N���vD�bS��k�����}���Pu������
�4���۸#�;%�!��8U�\���(9����O@5F�
 �6]��8��Kq�� d�dzM���;)$�6�)��v��n�B��U�)4.���$�LC���cփ��aa!:�Q�*2$�)���j�/���ﳠ<q�W����-N<^�c��!#^��JO{���n��N���m�=n	a���ʘ��/.�)�Mj�=g�/!Q�kaw�D	�b�ehkblᆖwaUؿ$v�%�ҒT " ����O�r�/>lP�^s\<|@�����
}�G �d����d|���A,�Qn�	�T�Exi�5+�+ֵ� �E�o|�c��G@�7+�$�U)ox�w'��H��>h�صԓH$p�).��x�ct +��������|Y2�<�rğ_�8t�O/F|HZY��	�Ӑ�y���!���ς�9��7K�P\��u�e�z�듯H��!
UN�Tv뿍��r\�QR�������݊ ��۠\+����D(�7>;t�v�i��)	<Ps@o��{�������`	���}��~�m��\:;�"E�����"d����Ԓ3���IB��u�B���S=���e�m�D�-Jδ~�)�X�`�.��L����Qm\dǫ���!&�ᔺ}���	�2���"���_%�I'^�°�F��/�a�ϛg���>���m��XQ������SR#��O*7���;O!�h		Þ�����D<�EO�_@���-�)y���Ը��9lĀ̄��z�t&$�3@)@q�.V���]�?��/.i9CE#�?9&�3��Q��V�k?�#H%��ܠ.����`Ÿ�	G!��o�)	���m�M�+8�e�����v�uvI���]�7Fn:�CJ��:.K,�׽������r@g2      �   Q  x���˒�0���)x��J(d'h�w.�X�IK�4WQ|��請��*�}�9�?�R��}^��y*VV C,=@�����(�����x0��:2���`���w�
�����׷�-�R��0�E�*�w��w�3 �����!����{u�����Y�	���g�ƥ�/6}�]`UY�>x, ��
A��M.�!�T���.���~��D����Up�Q���f�Y��X�kV4�
�n�c��b�$!̟&�2�ʦJ��X~Њ "��8hi����d��"d�x�,IX��4�)I����/ӽm=ɗ�i���'�����-�!S0j��@ZA!Xiy�ztT�s����'.v雘���xQ�7�Y��z�H]^�+��Q���!,�8K�����
ͥ+ɋ�r�h����]A�Bk���h�`�6��+�>+�*�]Ùe�yGɛ'VVt��J�Έ�'�ǩ㼩~����E��]�(Å�+���|�vX0��K}�%صq�o�=�N=��C�=K����C�G/�o�USm��j
�U��7MDD�c/ɼ���q��>��aV�<��:�$�[��?�^�/VN.k      �   �  x�u�˒�0�u|
_��� r�qSPQQA�f�\�EA|�����*6Y�qr�(��}lF� �@�c-�Y|b����#Z�8������`��jk��؆.�-!9ЏZ�ԥ���V�{���� 8Z�/ (P����m3Z�s�^�R�u�6ϧ���0%��~�Oz�mX�a|�,sE� \�\��:�����b�=��{2�G��pE=�Bq��$����+s0�YED�+�6��#��=�����%��}��`A.nz�SK��(����^��c[����\1"�w�R3�_����>���/�\�G��;�]�� �#W�L��f�]F
=��d�7�r��Ӳ��w���ٯ^�K�%~,�lC��Ky#u!�H;`�[�_�&��%}�̖j#��lz�v%��K���:�evMu_Zoe�,{g��+b-�x�Ư;P,T��g��sst��R����ۛ�!��t��u�{f�L�&�}�<��d�hw��n��UeI�S���oo{ �%�]��a�.��-�o�a2��Uy�|�ڡX:�d����2���py����U��i���	*#�1���!}
�k�ӸRV�Fj�O@Zo�>ZV��Ĕ�����r��b�W�t�P)'|�}5�{f�����A�:�*օs�e���5�ŵUc#b��ϙ�ZE.wZw�d]o �˄-�Y{�u��
	�K Dm�M1<�۟@vr�2�%��0�- �����z� �Û2      �      x������ � �      �      x��]W��Ȳ~�����}�; �O���s�FG� 	�č��W��#��9�l�D��ʪ�T��/Sˁ�a�Z�W�t Y]7yY�n"������5�M�ф�l�8]E���?0�A�����d(�q��'��f��:���ds�N�Դ��L%�AD1�����Y�$�#������������) �����Z̗^���Xo9��$}��e[�:/�º�y/����^�_�q�vem�&+�}�e�J���L���B�EjO��ǘ�6'��%?�R	E�w;a��PJ�.�tM���
](q¬�w�`r2P�,.<'�J^P�`�//��~��l��K\���<-����5�t��Ɲ����p�� ���ځ�9�4<��),��K���qk�/�	4kz<��K��	2�,��J�ۼ�_kdc��&���|9�r;-��0?��U|�U/GQd�e*k�%���z0�q^��E����c	Wj0L�w8b�k⼪l�|W�c��VwPx���xM����kxco[����<�N�v����:Hy+�:���<Iߕ����6��+�,�#B?��sd~�Η�R��]���^T]��;����n��J:�V�S~���M�=ֶ�ڽ�H�`���⋠�G��tE7���g
�����;{�G�����	Ƕ�ȯǹ���t��{��:�Z��,�p�2A�A��R����t�����U�n�QѮ��5+�)�g�@e���?,�����K8��%���hhX�a��V�=z�FM�o�h�:�h�����:E�e�2�xq�-U�"�&�o!����wN�C��ޕ���h��"1Gq�'��ē�14E�)�>I��I#�Ms�ɕ+m�-.�s.����M7������ǌ-����P�J����cŖe;�~�N� 9�/�^Y�+F��.X��6����I N���3H��П��S(�7�1�;�y�2�9��-�ۉv}V�)�B:��y� ��zg�C��d�T7�ܺIlf�6k.���BJ���j%1�nb4�3ǫY)��GiV܀�!�ogr�uh�~�GW��D�T�2�3ec���߫NXW.X�ܶg�2wH�6�^��	��z;�~�p;븯����M�#�	&'����N�D�*D�vTS7Ӗ�����[��������(�oﰣhZ e4��l$8?ւH�}5$�չC�;�wnǈB�[��W�;��m 7p�n�p4�E4і"�����GzkW;�z�5���~��(:}4�ssRd���M��F��!�!G_�`�w����X�uݳ�Z�b�H? ��ީ�Q{s?�
?E@ۊ? �-�ݢb�6��,��z�,B̴7�#r�y�!u��n������-�}�Q��:������;_wA7$Qn.OL��6a�� Y��縑�{�]���+��K�W"۽yϹ�X
��zD���4��Y�Ó��4״��f�1����}�w�眽��r'Yg0��C1!�n��-����r��$�4tVӁ��,w�C�3)�sH��`��藠��K���l�1Q�isW�W:v����_B�|�Mi�R�΄eGЇ=<h�4�E6�N������i'�ӼK�t�BqˤNw�y���ꭴ����Կ����]�<������D��]o�t����j��G�����1>�?6�!��a�d���\C �E����%|��t�	|RT��p|��!�y*p޳�Z�#�*k�8�(w�;���OS����d����s 
��dQ;i��?y� �-�1��Q=U��pQ���8��X"�b$�&�6�;F�H4�2�i8�`�-X���<�b���׸>&�HGv���3����&N.�������$1�Q�i��8!kt��ɳ|��I���9��"��taLe]���bVx6�ߛ� ��'�BK��<���,��W�=�?Kx۱������l��$�9ݧ�)˩���u6�cwPE��*�b��X�2@~�Ym������X��`>s��3�m�PG:�<:\�Q��#���E#�Y�� 4�y�\*�`�d��=-�K��D��z�`�&7���J���
��$WN�l�����"�{�lrsJW�P�j(�J�^y��V|��bW�f��q�b�_-�Q�z�V�)�y�nr�AH����cAP�ޕ��6�La�5����d�J�8�l�F�'����i�_
�K�~)�/���z+P:�1��Bo���K�]n��=	��h�i�M-t����F�hQ-t���h\��h\��h\��h\y&��G��N�3�=p��0���"9�<�J͉):��K�s�����*�$Y�y�����wp���{�7�6SM��zK] Kt	��"�.a�Z��%��=�rB��)*t	�p�] K�Gg5��F��u-��1ݷ„t����׈�T���a���0�?�o�|�EWT�X��TCExӷ�~�v��BP�Μ]�ӛ�Ll�%�n�t�*f��u�ub��7�-��S�X\�9SEr���槙�̋��>�2I�	0IR$�a@h�;F�,��i����\��Ҹm��\u�4����[�~MX�B���׮w�c{��˱y�Y�py��F˜2�ݹ��xiV$W�P.[򸆭��G��zAQT .�����E��%R�����@�ޟ�sE�:�����6b����4}���M��u��\�N[]��00t��'�7��,�Al=�k���BK0v?�H�A����6�H��b�O�B�4�Hy��W�Cϩ��@A�醘nT�@eT���(������TY �8|df�+�y*�_��K_�
�_��� �!<��d��Xa��R"�X�_-i��X�SN�~��B�p�[U��X�)��Q�V�߿��Q>��o��}Jwѥ��}؂I��s����x��S��j�#3#h�A��H��HO�����1�w�s5�/�Ǧ;o%�����PʸԘrF2C����V���-�db�F;�1
���O2�"��?�<��&�ь�I��!�}����ʦ�RGOg��� +���?C@�c�@�V2�I[��-yR-	��|Q�K�l�=���3qٙ�h�Q)+5!�s�h��"���˨���މGF��K��Y�l��������m�blc2i��1�o�<�rOp�Lwr�jv &��\�z�j>.���Yr�&�E�HK"��ܼ=K�.1�&S�©�4�W�5�� �T��(cI�&ۺ�(�3���@�.)I-��na�.���tG�Iz5k)vw��;F��(��e�֎e�RZ��#qXn��zE���~��d��]9i�Ӊ��z���_��6'T�[�����h%�Iv��@K�l�K�Zl�_���D���e�éH��q)��Ps�H�����;6�a��&9��*C iV6O=���_�f��$&q<!hVM��z/_�8�Q�:α�4:��./t�Mm����}��Shb�����,����+z	E2:/;�P��l�!|���Z]�[n��Z)��3�f	u��.G�JaV���
9�Z�bT:�j�a��Z؎O����a����e�� �H �?5g�#P����Dk9�nU��RA�#O;3IJ�]L��ӕ=�����U�ʑ�f��6l�i=3.:0D`��3��t�)�
%-Q�����Te[�%#E.�VX|�(Й9�0܎��vԨ$R��PL�ֲD��\Z�i�X��G�:���Zk��^O���fzܦFXE�t�&��j���=N�o@T	���I}�m;���L�R �3G��3�Cz��
�]b)eڝ��U��qg��H=G�3)���t�\$�lA�[J3*��7��8�`-���6CG�+`x����	�Qt�^a�\�[��Hs��XP+ ��6����ܛf��K��6#����|�Wfu}�S�Du�*�H�;�"�{����lI8녮�+�!�t��:�P%���B���P���4H�FbV�ѷi��)�̆9~��XػME�\\>�׉�|��O���gS�}�a8���y�eeo"��!oX���B�#s24�AO�X�&��G��)�,�1v[���Y&k�"�oϹ_��F>�M�W�۠ ;  -3&�}�S"���^�Q���:�m)N�<6�q`,�[P��fm�K+�nwF#�����:9Z��L�^��u9L!��z#�z/�T�S��F��`�n�*iBnc� R�%�ߎnB���f�ĉv�l	ĀK`�B �-��3���-#F����̍�<�z�U���\{�c�]��ٵ�7؏�|�>vָPK�w�~���������	���y�(�tMK�(�_��ސ�X<�N��P��U��oM�g���\w\_�"������;m��m&5b#���]3]##T�J|U��\֚8d��r�l�ބa!.�IqI0l��P��_�.ϥx�`N�R��Wo.��&��@�E�ב���\V���G�|��
4�-�E[w�I_֗g%�t�0۳8Ƹ"+ǉ�Bf�l���E
#�]_�%-�g���ͧ�!:dA������W���Ax��I�� \��N*��	-vR�-v�kV��Xk�"Qm�s{6�١�f ����} 
3�	�l�R�X��ZFˮ+�*;,�+�3�ukdZ�L-����DIL�-w N��2�sMo]�o-0l�q����#�u<L~�0�������w����[���O4��o����r�%�Su@��!#�F�4=d~��H�[�S����
�mJZݑs9<+n����.�x�^k��z���*b�s��hԑrd"��:3�0o��]��O��2�P,#h1��;"�<�P��)
;]0����N[�m<_�^}��e�<�n��n��\�Ȑ�y����L.t�Qל�՟��B�5g���Ψ��	Jo��V�2�.��h���J�W���p��M�Kx^��ex^�[�(��Jp���{�#ڟ�w����Oж�HiK�+����
�����ya�@��4�I�=$]R`4�+�F�MF���c�o~��� \|j����g�����	�3��{
����) �B�aΧ	��~�]�Q8��a�_-i�F�|:�Q8��0
g�+]�F���v��_1Rg����a;#�Ј�=�d��q>o���X�(�&Q�AQ&(�A��w5!�����?�o߾�?c	      �   �  x����v�H�ו��:�52�S��8"*zz�� ��O߅I>әՅ����g�b䩦4�$߯@dгR��[a�b�^�?��޼�c�wQ�v�y���W 1}��#&��T�r��}��[�$ ��T�?�zˬ!�b@�-�6������f�-�T	�"�$?#'�FYL�l�)� J�ɥ�s+�h_<�'T!�B���
���|/�T�N�͢���`n���qr��sPv�$�dD��3����ֆ�
7!U���m��N{aN��S *�����S���T:���|(4D��em@�_Si}E���؞���(3@���������j��qm�_LjJ��~��/�U�5q�(��15U��Tľ�Z���tj#�m��0rmK�3�
UL�@O��Yvd�v3��o�����y�O��2OsީLx����B�Q���D�$�s�7�s�5���t1�6����)~G�����5ܢ�k�	`�� ߈��_�EgrqR�Zڭhdt��b��W�)���n��~ho����?=ͩ�z�O0dǖ����.*�cWjF�"qF,�|dz���]����XEi�����X��ވ�]���|>�"��-3M�Pp�ϕ,N`{���!�z�fz ��x��vg��nz%�
F�Ȫ�M�46�͊X.��'3�wϕ���(����K�PA<���^g�
"�-��M��ɢ�[��B{�n�� bĨ���5MǍq�#e�^�nV�1�G�ŮV�rq��C�a�G e��)�g�9K� T����%ocįa�J�O7J�7!�ϛpbY�Hz�q�T�oj1�N��y��J\�u��B��ß�C��$��������IX��Jed���v6���돛�d��2�n�X���4B�W�X&��hR���zSq"s?5V�qaz�#`��_	�K�X�ʷ�sz��Eb�(�m���@܇1�n=6�0>�yf�=C-���R�-����1�)�-�Ĺ�+ \���{n��Է���@��J>hN��ֱ���'�q^����{�+�����+�|�(�B\��ϣ�@�[kh`9�]��t��b�#��k,jcA���j
P"���I�8X���0|/#����R��h�rt�/EQ���N�ifi�(��Њ�%�&�LQ=m��!XzK髷����6]a]��sp(�#�u�[�;*��*�h�˳rk`Og������8������=��:�W�b�LvE��F�H �����~��jy__�_b���zM��R����ϳ��h��y��f�A���=>(?��C���$zT����&����*7�b��G[��ּeB��̽k��𖳒߲���'�����s%��:�5�S�xAZ�2u<|��}���p���xگa����I���A�=W�I�1��	��]ڃ�-C�&W��u)�F>��,\�V���˵_��'f(H�?Z��%�����B�r�Y�W��s�r64ȵT򚧭�7؁�Z��T}��eHU�d�H����կ���V���p�*_���=|��V"����}I�Ŏё��.��0��bn�ژ�[�?vk�G�=��%�U��(j���B���S������l�J�C����\��U��d�Wv\_�6_���W%][Ah���y�Ċ����n����g̛]�MNR�����"�,��G'��$ؿ?<<���      �   �  x���ٖ�8Ư�O��3I lw���`�����
�"��O?��v��s����K}_U*�^i�����e<v6�E�ݟ����ղF�j` Э�oW����F9�`���,d�Y(c�� �-�&a0[��iYi�f�>@ 8ɉ���L�F�=��|50M/�� 5;��4ð ��$�D�!��� �9@�oA���nizdy�����-@�7\���*Ș���2�z���	ZY�e��`��~���,e8ҍ^� ��x$|Q�����hy,�}�9a��Q�m�ԃ��C��@|��ㆳxҼn�
3��'c�Y�u�=�����c��#��y@V,�}~]0
��0�ZvbZx��
E��ꞁ`�X�(��q�H��'e�/=s���5�d�z�i�JH�7Y�V����\�*&��~"Lel�}_�1jo�3u#���2b���1���`�h�)v�љ��*�&����Y~U�R�̊�1����B������}�H�8+�@4|=��a����� S��b��J���x�����U�J�Qm�rUJ5)�'j�mEǶv�1{�DͦU͕�vB@��8lvG'=�"a9UB,�͗%��G�Dw�z���.3NSi$tJKm�A	$������Y�{]�(�@�+�SL���&F�X�҃����։���L��$�~�6\]���SK�#=^�9���)٘�8�>������]U��.sc�9	�в$�3�׎b����>���Vs�L��0��ִ-8  b���ɛ�}l��h]F��g�_�y�<�uꧺ���+7���V[_�ћ���.._w�uL�l �A����aq�5u>��������p��
`�3�\]�h��!�� +�������
ɮ����,��V�Θ,�$^�̦��� ��6:�����8v�n��vvW���݊_��>�1�����Y|kg���*MU���h��S{�c(�}`���r�D3�Kq�<FG�r >���Q/�q�������7ۛ0���(�&��u~���wَ0n�IID����:��t���x��}xn��C^&�1��A�$L���z_f�LӢ7���M�_}�r�Rݍ�u��X�ph�V7��-}��`�*���N]鋻��i��~Wۋ���<-�a�#vN��9�>F K@��I�T������[?n�_�l�×�M���w}@�27��_�vZαXv��)"��kљ�5?�������_�ş�_^^���      �   �  x���ɒ�����>��
������'(� �҈��?fV��̈7�p���{���>h�Ү��J���ِ�8.,rը�p�z��a�!���/~!��%�/1�G���l���
�.����n�&v��q�d
�E��y�9H�Y<��x��>x�:�;t�]v�>c<����7I����muvrk�D�(�G�x��/��y�����s�A��s/�ϼ��y�s4��qC Tu����U��d?#�{x �w�t#� �	..x�y��U���UK_�U��&�x���p-Sef�<U�VN����\��;���|�!�[�q��Gmoe�&bl����~��sT�zz��;K��I�v&�ʖ�v�l|c�כ��7��_4��P��xo@�a9"�OQ\Ql��!��C?\C�0��F�,2���K5GF�߯��b���E������+��L��φ�tW7��5�v��ۢ�v\�]�s@���L���H�gm���~�K�)�w�a�ܐ�f�8a1y���Y�M<6���b6�{��p�J���h!S<��7�Waf���<-j�A�f1���^��ا1��b����QK�vAU��֒c�YU�{����!+���'9OR%�\?_�5ȲPjRu�e���R��{���yC�}FN��F�NCZc��ѝ���q�~��}<��yw�n�i��7���4`���m�':�lkz�7˧���~���<�_�����=�������x3��M앵KW"�O�`��p��Z�(-B=�0+�I�؏��Ἣ0�`�=K��z���X1l�B�4o��C���\�XI��2�0�I�o8��^�#Oh�E���A��{twYƷ��_x�x�7�GbÕ����Q��|�r�[�o_vﱖ��DT�u���S ��?���w ���u����Sۭf�"�&�3�� w�
��/0���F�c���L�c��o�A�ad���A�w�-M<�
ir���tr�W�`F<[����h�������!?���"3�����JZ�.��+芴�*mpJ�'#�+G,qx�Wv����*�RJA'y��~�#�r��
t-�b��I�p�|������$�k,���BKl�}����!�~�`|����O�"+�	�u7=͢Mj��S&�	�;���7���6�D��"�%��y�����+�(\���r��c����&%�x�o���W�)�yWJ���<kƼ����c�M�hW�V���)3���@블;�p'���/o诣[L�l*o{�rgB3SD�i&�Y������_��K��)���'�k�ot�}����Y3Um� �������7̟s��<p�4� �0�.�K��s��4ܺ�����޿� �n�:�\��n�7l�eD�֕[���*,���Ix\+#��<�l��`�𠢰�)��חa���Nh�^S�z�BR9��Z=n��P"���(�(�j��"r�ߖ��[�A'��2F<�g�PТ=�V?�WŦz�C~��s����?�m)-8Hn*�舄���G���z'�?�u����./���6Ӭ}f�1u��u�]a��d���̮�V�F�%U)�slٛNQ�����]��Ba�F������Ό��<��~l���y�3������l6���~�      �      x�+�s1���Lω��p10�44�ts�52�,�(�4��Lw1(�t��
��JM-�4202�5��54W04�22�26��������M�IML���̏rMu//r�Ov�H�44��hJ��V@�h&��qqq �,      �   �   x���K�0 �u{
/��kK,�"!��47�(���xz�7�&c�2���]y{O(Ը��s<N,	G eU�2����Jֈ(#QBy��}��T3��6.��e�������v�����
�ó�ы��n�!j筹�"�;:]+���(U�l�/;���7���V5+��&�����}�� c���U�      �   �  x���Ys�L���_�U�u2�͢r��������i�UdMn��kLL%�	C�/���9p8�վ�S�xC��x�{���ΰ���+��k�۩�0�)�.�!C����	 ����jO�@�h2��1�X*h���9S�4� ��Yk!�#�i�|��h������9L)fI��שּׁ���Ӌ;��s�{`U��|�d�4FA���9���}/�w�l�&0��L�6��VO@=7���mR7
�3��9K����#�3�v�ק����OA�5D4r�{�ʽDh��tt��=c�7K+,UC��-�}'�~�ϫ�I՘n�����8��1����?��<��S�Z$�8��!�&�t�ϩ�޹�g�k�$��z���i�0/�N���b�q��WׄSo�>�֯<K�M���q��(�53�AY�'�n��[b�_����k�M�?'i��CM��/F��Թ�<���4`G��Dc��yaB���߅�n��}�K};�����;�!�[����3U���<�k��ި�iM�{�l�׌%�����H\8|�8َ���FX]_�M�h���Z�CA��)U���[��N}̷c�ߔ"_%�c�R)�5�}3V���֘��&�RN}������������`�Z����Ѱ�"e�2<��VPOaH�z��L�U����I�	 }ӝ��ᡧ��N�]YIW#���u���Ii�������|�x�	q��-��wHb���Bn*���~`�IdK���^l���0�Ǽ��lѪ��oH�
�R���BfӦ3T=Ya��:��ߙ�(�/%T�W�R��P��h��t;U�^vF��<ȍ�5�>��� 
������g�78.�Y�ר�2�Ld����i>1�R����7tq�"������?ϕJ��jpE      �   �   x�m��n�0D��W����	�o�)A	�@@�`Bb
��4�DO�;�7������no�ۥ1�h������(�{�&$$h�!SD�Fq�O�v���B�See�h�N���4u�����v�����쉾o��*S�I}�h�� =�1J�/��xB��6�x�"y���Z�*�Ys$c{�ں/3}k����O���|	���2�fjR�؜O�1��Z�      �   �  x���[s�0����I䤗u9�@#��0�Q[+� R˯��=�4����^d�M�d&`�[���|jl��)\�g]��O�ᖜ1KB�,��݅!��j(��m��r�b垣���~��4L?|ʼ�~"�5�-����<w�f��h|��BP���zNe7)i��]6����3+%H�;g��BG!�-��i��o���ڲ��m!(�Lb<L�����O��-���+�.����U�/\`[�x���Jv�-U��ȀmEE�"�8��d#����vWz���.Ū*�k�FU�le[���	����z����I6���Ϝ{AQG�����l�Wad��L�ީ����m��(Ə�~d���m�-���O]Eyߞ�w��?��7�����O<=��.�߻�\�?ߵ��5�6_�����}	l+�낷�[�s���}{!I�37s�      �      x������ � �            x���ْ�X�k�)���v�SPDEA���� Ye��m)g��G�6��~��sH��`�žtr���	�0����D��'�j/r�zd�4�|����K.D��SEj��7�|��;d(1 (��ys�D��v���oI><:z�\#����&Gb��vxR�Mv��/c��
��S�,ǇD���ܶs�Ɓ���[S�/z>���>�ɋ>A����	�,$V�M��;~��Yf�Fp�n^�>��h�,�����pi��귯c��
@�[��lik)f|�0�,��~���-�?7�$����wQ�	H=�\p���˴�5gl�D{��ȫ� � �h�չ��T7�����=j�]��&�LY�� 2F�x]��/�mՓ���q�2�)�r�=f�1?�E����vd�����4���(}��E�͊䴚��q�o��6���D�	>v���Q�8I��Y��V�}Q�ݼd6��#�Q�ʰ�����+rwk#�A�{�h+�^��t=��L��C�[�!+�����̪NG�ٿ�箝g=ᆂ�G��K��;��u��~� �~С(OGƂ,����W/z=�������?�ĹDB������o�o���T�0�FPQ�b ��+g����x�=���<f/��H�S����R��*d�+�gM=�3@� ~^��ʣ�����.�x���?����}kJIk9s+&p���~�i���- !����G8؊ց�8Z^�K��a��otk*�Zm�ˌ���P�5��O>]C]�k��_�z������C�p�`r(�J�1�i��f/͊�_l�9���!�9��t;��B2�;�{��#N��皠�;�N�?��y�9_�h$'��m�I�7��
�/|���m����	J��k�������/�ۓ?���,�����I�W�0��x������Bo�ac���,2�tP�&��H+����-��t��}�U#�y� �J��*�׊���¯sB�
7�%�rw�j,Y�!r�!Nr����2���ĳ�g�|{{�	cY         �   x�u��
�@E�o��0ތ��̮!I#!Apc8��!:&�}DP�hs��eu������c�k!+����q���E�r<�����w���SjmH6��3�v+����b����):H��?yL��;��X�إ�|��'(_0z2��E��\��n�B��SL��+B�*#8�         s  x���ێ�0���)|���ĩw:�TFTT�$�rQ�~#:{M���I/�׵��X?�A3q܊ܤ�}nu���"g�"k�qġwP,\7�i����)���v�!����_�"EE<��r�@\�P��q{��+� �)�te
�RwK�`���dg��݌%�*d~��Iѭ/�@������ �:ʣ�pO�q���n�s��������U�/�����6>�&3���)(��zxت� �Ս	{��A��ڙe,	3K��-�� �2%2�S'���r�x�B�xF Ws����~�5t���g�L��.L|�=aJu S )Jo�sD�t��o{������S ���D�\"��Ŗۗsc���6��g&�k[���F�UD��C�F\!�6��ٸ�so3�i\�`S 擨��hP����E���z,c���w�z^L�9vݷ���ƞi��>��;�C��Dͻ�[bLr]\溦�93���&N�˝~���7"ECJ�j|<If�s12;������I�9���1Ъ"V*�qy�%c���QK��̹Ú�"�}�a�&1������#N���CdJ��Ϧo�0/ɩh�z�2�L��<�tU+��M�)A^��~��j m)t|            x���钢������*8_vt��T7���o� **'�D) �L�w�^˹��8TYU��O�]�Z+��1�V2�V<�׫���ᥳ ��Ց��AL�@�zq����{١H��F��H���M��&{M��L�r4�kwa��`���6�0;۾�5�2/��e{��I��[��)�ӡt��=�D�6/���܅�]�7k�ڗ��]�M����R��af �'��t���c Kj�V�Έ$&�I!|���⍓�Niȑ)?ZD�Xr�q�<�!������~]kc<�o�B�5�����&�Jm�~(�Y;�&l9Y�(k���:��J𢵧]m�d�ލK�uX��#mOq�m1u�lBy��|���-mO���z�y�����k_^����u|
v�k��{"�(�irt�@�C�J�m�yA��%	L��_����e�f�Ռ�.�i�l�`ԗᢤ����r��FP��)0Z�� #����垈  �S��NR���3�?���D�V��=��"u�X<�]�/�{Ҟa�4r��w/�J��QG5�����Qg�*�&�bLs��$6I@
b@ݙ���\mXk�R-q�9��w������گa�j �֋�H�
����'�=s��S�sZ�^ ���K~U1z^8���ii���:!�^g/Z{Z䫻R�́��Y���<}�c�D4CIf.�QH�.z0���]�'���A�0{�s�x����h��ʰ�*�2�e�B�1@�H�S*yJe�h��&f�-Ly)�_��4j�I�Ԛ�d׳%t��`�몶���}m7�/������M�3j$8�������M�_��\f�Y�L���8.���2�����Q"�l���{������U��-��\z�r�n'k������o^�����l�$C�����1O����yU1F�CxN��p�V�EI�f�x��$Q�z�>��j�8D�<�b��@��,�]"��^����b�E����~=@̀"���ikB��51���C��=���aN�$�:$������5&��hk-��cO8���_�
��`�#��?��~}
Yl�(O����p��D�c��8���D����xl���h��,�R�Cl��C� �-(�YCNhHM�M9֛w�����6$��_r1�J�(S�
1������z�M��2���9��^��ۦW���4�'�=�yB���\-�ѹ�X�#��]����>`�\?M�²<���y�����jϗ�˸&*���^S������lO��ǭ;�p�TsD�rTd�e���D�f�xJ��+0��;EC'�Z�:�'o8{^��C����<��r�~(�Ya`G��G��T��ϻ��^��*g�U�ZP�;{��N��1�V�Q� 0����B���ҞP�j�FGʘz�/`�r1�W��'��W37���psK�S�v�*�6t���*P�����Pڳ�9��rK��X��0zU��Ɔ;N�����M5F�<l�0F�ŦcW�1Tl��b��q���=�J��8 �'S�I��QR˅/F�K۾}�g�PY�=�ql���8$~�2/���������lS��5u�x���q��9�t�*�!��,r�@�3����ў͎�u⊞�p�d�jp���rkԐl��?�a��d�����/�ַ5п���y��3�T́�����+���5��� ��Fi�*z��z�#��"gY��ΜO�j-�ʏ)��ce+
ڛŚܜ�ɽ�s߈�����e�^�a=�%ig|f}��W�Ŗ��s�j�u��&�w�=�����M�b������Q����ň:�Fw8Bo��6(�E��N�����5��w�$r��Z�[4�&�O�w����������b|x�M���~~���b�T^$���2Шo<��k�1�rY\��v)��6�������?�_�p�}�w9��O��W�vo/|./'ݺ�~do�/�����♋q�'���G�h�'�����Z(̵T�����TP�d?���\� {-�3r$��F=)�ï�?���E��($�k�4s��R�Uň���Y����~(L-/l/�l`��=s���"�ǧu�>0z
l/r9���Ӟk�nE{��*k+!�(� �ŷx�C��r���$=S���lm��&t��QX�ka�˳�°���KK�7W���%��v��ZX�c5%���(��DW��4����Gڞ�`0��#���yv��&~<�{��r��`�d�0�*Υ�y6,�O�Q���+A���o&��� ~U1� W\�`w�i�l�����A�ԁ(D�CF]f�P��c���D�60/{�{ݕ�Òr���c�O���bD��H���b}�E�Q�̽'�N�+��8G5�_$Ӧx��Oў3=��:+Ez�F�I� 
49���'f�MG�*؈�)v֝���G�Ddơ�����,sD��U:ZH���[�m���5%r��_����uƶ����u{��m�Q�g:�0@��=ŨC�:=��>^�Of�Д�G�A���n<_d��f��|�4u�J{֠27{�ti'���DM��bl��YX��S
���z��2/z
�s���X�Y�����r=f�E�����(�`��� ��K��EkOۮ �'�2�"�Z�7��b�@Kmypt�8�Z��y ����U�
^�"S������Vy��N]��`��f��5�Q���^u���h�3$~�ۓ{�,	�ִT�}C������l���&�w ���P޹�O�;}g���?X�����Ҟ��o�(���_�$ob�QԻĘ�ל!X
����¦i>$�6���������$�,��h�zl�]����ݰ��#&9�%���b��Ғz���2��s{��8qj[�)|�C��\���4?��������8}
�d�y�b�Rã0]�@��d��1�̬w�g;����)�?�|��JwtM#Dx�~���� �a��Br��K��F��S`�.얱�^����� G��縄�e�1^�f�M�=q�0C�,��h�Q̈́�����OL��y�?��м��b���}�TX��}z1�?9�O:��18h�d�{��I�y��Iǈ�O�q(����+��򤬢�=M���8��cU/�����Z2��ڞ7���� ���U�[�7���W�=ѵv���+�!�:p9���ǿ�X��ŕJ��Us��&�
�I!Aq�Ë�����y׼����>R�EZ]ʠ��}�C�֭<1/"u~��S��h���Z�y�3����s/#h\	�- �c&Fd�Я�`�zÀO��,/ٻ�hіlH�ճG�)�ψduF�#�/V{�n���R���:�u���o����"�*pEe���5�����,������G��=���\p�xֻlO2�����GA�Z2�� h`�����rmG��lr #�m����	��䧌x�������W��- 3��R�ͅ�)��}@�������zC%���IO�^�L<`�)x��;9�����@#���I@���c�IKNȖR �L��/4�'������x�x��.b]�^�z	/��I{Ɔ�����MEų<�'�Eǈ�����b;��uљ���Ȫ_�����RI5��ƈ�r��~k��=����^�P����~�u[0��~��Ȥ2.Ѩ�65����ѡ���r��4U!�=iψ7�����z��ŭ����k-�w����vS��T��"�x��O�9��+qd�$�agR���|3UY���_��a���#�z���.Zd���3�M��_"F���!�s���2�r�wc�< B������S��.��5�.����ةW�j�Ȕ`0��}X,gc�Rj4:��ݙ^|�p��bi��i��~gJ(A�=F�����3�m�XIK� J{D���$4�ZG�vߦ7�mR/�0ra/��+\#���Pڳ�Y�g�������;S+-�I{Ʃ��d�2cZ紹ҙ�^d�C욑1Bn:u�Ĩs���e����ip�t��A(�YL|���hX����ք��C�+��(����eȠS�����֞6��L�{�LŪ�/��u�)Ʊ    R���07G��)���q�H1�%��&7_ӑ��<��
F-��`����F��LC/�b��A�}60Ɛ�x�q��]A�S�id�y�c�.g���+�+b8&L�w��/G¢���<�yҨq̛g
ю��l�3�_���5���}�Nʾ�3|�>��Sm/['=a2�3͒�˟�=��ǓBq�)^�]�d��˲�T�1�;��w�6�2u�Y�+x�3��#���u�9rcn	F=��NÃ߿꾴Q���O�՟O���Gaf@E�"�	)jN»֞)���D�a��T�/�miO`}�B2�����;3�%$B$��=m��;0��4�M��s���)0�}��S+b,K %� �� r�&F�wG}�?�ҶN�J���)ۓ��"�Q�y6j*��γ�O 1��U�{��L����%�(Z�>�w�w�2.�g��ZW���Ga<~�ܜ�OFo��H�~���Z�y�]��1��?�`���ci�~���y�˯�7����ԉ����W�϶2eQ5� �Ӽ-5��,6��Dy�E����ax}�t50�d�+���� t?f�?[��L����e�����<+�x�}�T���j_5�寈5<Fd?���p*�ҍ.�Y ��9�|���S�z����y�!��v��JH���)���ש<\��^.h����'�=�f��|���,�=iϐ��et��r���i���C��A�˴j�{���4w�[.�s�Umϻ�z|Z��5��C��]b�F�뮙��<״��Fh��]`������J��B�B h��;0>4�z{���F-{]�_�����s�ۂ>�:��7�z�BG�,�o�@Ƣ�3�x���]�g�S`x�,�g5�d����4~
�Z�a$n�% ���vxB��Ԃ
�L��p��h��k���)��-��խ�b��G�j_��IC@���=KV�A�+p��������@���v����IG�`s7�^V����߮��mWV8[l�L��ۊPĔ�^�X�����i=�T����6����>4��d_�v>��qnD���Q�c��c�.��6�l��Cd��=%��,I�g���P�0�'��WG���~�t�*��t@P��IoO�o�b�V��8�2�����&���h�|2���;<�wsB��f�^t��^*�SE�P��h�(D׻Ę���e:����
t�b�?.�~2�3��!���_+݃(�S6�_���g�=��㑙�w�b����ߌ닁�Q��a�?e�(��b��SP6ϕ?%F�0���Q�|����<�䏆��b�托�P3:�H��ǽ���]�\9ʧ>�R��O���c���9�^�Om)�x�L�B����zՇ��-zN�]��-�G���E
�a@U@h��_��h�C}�׹V��.`:|N�xi�?�g�gWÅ��!Ƭ�Xh�̭�Ҟ��A`�`;s�Y�QE�T�=mOY&�I:�{M;��B����9�9�)���F#�'���V���X�d�Q�$�i{ʐ���Q�z�L������k�=3>�I?�F�
�of�=�C�8�p�m�bSN�}yY�ޓ��
�2�׻��o���� �c���]MxA�W�b�t/�s�c����}��m�&��4$~hq�G(����1�2�3�~u�KY 7��[.,��=&O<^�����?��~���(O�++J������=i��1tM��R2���#N�j���Z꫎1o�mn"��u����(i �����$ц�ݩӻt��?O��*z��/�����8(̧h����B9�S�$��Ŧ#���\��hϡ���zn^F�u�� �Mϋ�?���ɂ�浡�IF�j�#�����ޞ8Z-�.�������#F��D/*�&�9�����<u��B�I����cu+�a���G ��6����h�O�+���\E/�@@|D��s0�E�rmn�í��*�����g�{F{�=��y)S58|��n��ݬV�c�����R�J��2Ĭ�����h�̧ǽ��������3���%=R�>vcyR폇	�q���#�E���f�O��[[�z�!�$@��P����j��.���{v�u[0���bȳ��9�f�zߔ&����#�>H�d�yUx��ۂ�o&1?]��!�K�)������찀�2�i�3Ν���ax��X��s?P{PWMT��А�Q]}��cx�+3����]��`�n|�	��eG��	y]s/�-��iI�j�[��LE������~���֞����	�8��2B�����o[67!K����I?��ns�9f�?2�B��h	��)��]��];Y'��O���-&�Gb��9�����nO>(v�G5\C�V_I��g`�9qPL<_tS{V�vg�t�C�)0jްR�[I�.�d��:��z[0�r�ʮu�U=�)�ґޚ�a=�߫S����9��xۭ:�&ǎ��(Nx����\[���N;����̯x>姌]��'O�|�4��#��F�|���|�w�h�4�"� �+q#+]w��Y0>�tG�Qs��)~60<!����Xf;����{Ҟa���Z^�Ͱ\�k�]�[0�̷�I��ǣ��+T��g����@��qz0�j;�+S���~� ԁ��lO�����C�Kg� O�����u��1�zg�#E�m�h1�Q�=G=��hhw�8�Q��.1������Mi7�6)�o������e�\�'��H��`lC�vg���~e	*��"��*F���p�f��;)G�Ћ������qZ��Vc�|�#@��q�.ۓ�ːKԅ�-�Ȉ�x�#�{���qz�s�ٞ�x��I5}���\�{�����>Ƒ�ٜI K�Şwd���G�^���Y����2�MtG���`�v�t6h02�L�ݎ!�
������ya��x��hkA������ĘOp����yqNiM�K��՞����rⶣ����D�=��O��0�=�b�]��'��uib~$���)q h,��/���ǩZ�o$b���z��������#�2M�mN�o�F�4I}�1��ڮ�"�^a�&��#{ ��Xz~�f[�f�gǹ7�� ]�} �^���{��QO�g�M_VM�F���!1�c|]���{7��@׋lX=F
�>@��_�4�h	%n^��}�1��9�l�WL��%֚�l.<���������A���}�u�e#w�y�"_���Ն��\��Tu��9po�L�\r�*�'�tYP��`.��+�����ծ؉��F=��D�����}T)�(�r+��~46�C��N�LG�w���?��0�ɠ��^mvQ_g z��)�2�s���L]+�i��AěE�nϲU'c?�Em�kJ�e͞}�g�������M�u�K��sqrl�͙�?���Џc�ũ7I�p>n��, p�	FZ8|ך��dZ�gT�!|
Ά�F��w�b%/tp<��n�c��/�ӕY	k��1��yu����y�Iu�Kr���wHFP=4F�r0꧙d�������/,��IoO��fi}
>/Q�c�ݧ��8/}��\f���stC(�	F�.2*��y7=ء��#gv����� tXM]��(%*��0�=���b�kc�i�SН�UdO��aTu9t��ah��� ����D{�D�)�1��."�p��h�)��1T��g��~� 
��������y�.�
sr0����g�
�\}��¶��r:iZdEL�Z��ڞw���1���KM7HsM�h1��$I����G��ؼW�)1b8��R!��u��!���%��6���Nª�5[�,����'�}mv�R��Ī�3�,��`���8���p�Q��m����=�r��90�%�n=�=�V��J{e��qw�>9$��Y?R��4��eE�r�A���x@�P(A�F�ϙ��1b���|^Z��A��⏫�����H��|U�����,<����W�Hؔ0�ю�es�s�!ǽ����E�W#V���,��w+{�oHiL�o��l`���r2Hv���k�{`�m˲�    ���j=�hFWQl<4G�yCn�C`�|T&��pܤ�i'��S`�r���W=���
�`
�w�qfW�iz(����<B�o�ڇڞ7�y��+MD�|�Xqt�Pڳrn�ÍC��i���jpoZ�F�	9�ߺ?��O۾��p������樦͋R�=�d��� z�"�7�D#��j�,��iYSBv�IǨ�J%.b,AV]{��"0oK{¹?�̗�j)�AzA}�m���v'Ե*�Ԏ���8l�9�i���]��\��Z���Z�f�/���'�"�'�K��6>��
��9W��ı��)��۷o�K���c�	�*���ϛMuB8�i=�)0����+�a�i٫7��&e�������x���u�5��4��1+p���q6�$��Bc&���<sa|�0�g���5!i��)��)!y�S������1�^�;��S�( I�#ʑ!�e����.�5�k޹^��<��ե�q���Y�6�C3;^�Iǈ����.���+�����W�C�֠.��S�䰩{�]��(�7�=�(]�#�t!��,o� ����<]3=�݅���� �!0"�S�ZC���	N"���i�ct^ϳ�b�6�Dq��6W��)F����ܖNZ���ʇ0�w��,��3.�;`�� BL�qd/F�|�V�`,���z��F��嘬	��^�����2B\�YG���F{���ŞBՑ����	�=�K`V���ؓv��,7��J{V�׶9�w�|3�������Pڳ�g:O8�p�bbp���S�q*�H�q#���UI2��E�*�'j��Kf���\�Pq߾-�	��,�)�[x>t��ie5�|h�i����0�w%�(�گW�=O�^�"�?f�*�ܿ�\
zW0ڨ��82@�Xt����{ڞ­��l{�jSی�mSu_����c�e2�lAw0��b0�4/xn?�j���FY�w}�;��/�O�ܯ�N?'�c�/�ΪOp������i�e2F�db���
����ȇ�1*�Kj�������uV�5skOٞ��)�u�Bg���*����×����b�QOTw��*�(��	�I�l	�ۓ�?���q$�Q*浴��i��MLG�'�(d�_*U�LM�!


i{�'����79s�^���*ɽ��%��MO�V�J�����$�ݲ���՞*��4_�Ӊ��m��)��S?n���ǘ�Z�å��+���PkI�����v��j��"���O�(�jb��놪�hz���Tn@����ϟg�3ڳk?ѣ��Wm��Fg�|!${
oy9��]����h7e ��I{����pc�X����٭x�҇Ҟ5����s��Y�`��؏@�����hA�Īk*m6�����%~|<���wG>��{�����ig]̀�=[�A���[�O~�1��˖T�t)ӓ{���oe<e{R����Ð/��<�����?ƾ��|T���nc�'����lOb�3�t�2���=	����:F���f�A���K:�2�-�	��Y����v�M��5��Ę��,���˵�C��ځ�F6�!xI3#�������Q�v�J�nlw��m��>�~~���Z�iW:7�#���'e	������u�����S�k���������W�=ק�S��W;
�C�ԙ�����?dax��@8Y�Q;��"X���e����y�a�7{9t[zd����qE^���ŵ7�O�P��#���`�ֻ�sng�t�Lɤ�4�:isQ�Emϣ�¥\�ra8���3�|�'�/�s�X}a��]o��$�w�(�.���i�_-�4jV�H�S�$�2�M19� ��{�������F{���"J��� ��P7���Q�c�b�H\�m8!'�t(=�����EňtF~j�E��i�g$O㠹,��bԺ-�^��A���ȣ�~�1�wr(@���Э����W�/\�(�ӬW�L8�ܱ�Q<p�BD�EC�-��rƐ����)��+�_,�Y�p�f��u����w�)$� ��苅�o�6C٫�`{ܗb�8A_,�5�E���fGw�Z#i����(q�(���I+5w�3p{K�2�c{�L�=ň��;�򫳻ܣ�y�Lc���+6�λ���]��9�|T��՞z4d}a.i},��A�	=�A����ݵ��P�uD�c�<�zK�3t���Z9a�4���?�:�����#�b�'w�pJ����E6����ҞE.<M���t@m���?n��bb�
][�F�6/��lo;J
Q���w��.c��ᦴ��!���~�Sbx�L읊�b�+2F�o�x�٭�{�Ah�U���[�5
A~V�dZZ��O�yֲy�ī��;���s6���_7��k��Cb��}픺JocĶ%�:J��͕�Wc��
r�s*npٽR��-F��Ӟ�<~�(Y� UB���?e�c�G���c^�5h�?1�)[u�!��u��k_�����o�����Y o�g��8^�ʄk�e��2dg]Z�#�p�
u�])�\i�t�۽�*��q��q���U��]T^�Y����d�'��%ر;[�4�}Q̇���$�������:��&?�Z��;���QfI���$�c��1��q�5�k��/��7��0�9�>(�'���`���`E�锋ikb?��=K�ϙ�K�u?[h��|(�"�(F�����1+�p���b������d�Ke9/Q���T�7Iv����h�6�܎���u�v���"��ä���=��?�b��UFܮ)��O=���=iϘ;�,{��q4��1:��e��[�qb�Syb�Ǳ�[�M<R��:9����TN�-*o��y
������9jn��R�������kd��5g�{V{>/���Ļ6<0���`Hc���|�1ڡ:��v9^O�ō�L���{��.&�~HԹ?kH�c�ў#�S_�ks	�삺����S`x�3q�&�Tm���
 �x��gc��C�T��,%5��\X���C�gv�G縼H�t1�3�,,�4?�]`��j0>��>Y7�ؙ�,;��o�ӹٮ�fan�)�ּ�����X��8�?�XL�n4c*�R��w�%A�H1|��QM̓�;�eT>s���9��F�xt1�2D�q��.��?OԴ%.�"p�^���|(�e)�䘨|���wT���q�-�����P]���?I��n�k��g���ѼO	k��P/=���?���TJm�My$��76a����,�g���<�?	u��L��q�7�?%Fd���>3v��|�@ܾ���jO���֭�ͤ�y@�,�'�ʪ�N��D���oś����ǣ����~���􈤒iRx?�̞�^���跨�Hvެ�@��?⺣�_�ۯ�r!�Er�k��X��T�0���~Ml�{�AK�������5�`s;߭��w�������6��ڀ˒���B��V�.1Z*�G#cd�S�Y٨!��#p�!���cެe8B�󏛊>홻Y�N�z��`&�;��1���E��WcO�y��
5���a�ѐO�a�������S5�\a64/hu���=�!5���
�a�pr�+����V{jГ���ħ�z�8a<bZ%is��=wU3G���G�iۀ�"���J��I(eF���� 8���-�ށ�gKe	/�"D6����*F�~a$�������AJ���x���i�]�ɵ!� �]���?_��\w�&iw��w�cg��=�g"�8�^V��|T����(3�-����Ζ*�Ji�=Q���l�;�X�ʳO:N���֣����-����-=�~�ʗ�P�ks<�h
�E��=�Z^�Y��\��4�?E{NuB��� u��3XE�� {���2g�^p��I�VT�@��v�.1���RW�Qv���D�L������"v�>�Ff&ɧ�3��5}��s"�35*V�̽���Ёe�͵��6F�C_��+z+��F���P�C���A��b:��ƴ�����S��0K�	<�i���~Gs�,���z{�.[��    ��qw��P�s!lj�]�� 	.�J�;(l�A� X�E��E�Z��� .�u2��A�K�������~}�j�O�?�,�>^�y��"z�t�I��0�~�\��nO6ҤZ,�=2�D�t	6z��I��Iv�t�����'���Pڳf��#7�0���\T`��fw?c�<��!x �i������O�gekM�V��@~}��υoQy����Q�����`䇁,n=ɷ��t-�t�1���Z͔�U4��]��8ɂ���nU������bbԙ�
i�n׿�lϊ�@��o6�,��mO"q��^�R�}60F��c���f�e�:u/�~������X�{c��3��z
��|e��}�{�W��p����]���D��"U����,sF(�wk(�V{�`�\�}Jn:	:��|~�>���h���K�;3��� ^n0%x�s�Y����h8okT��8���=���XY��SbH�)B���G�ⴙx�b����*\�a��^V�)q������'3�V��>�ڿ'�a<
p�`�,�í8�Z�̓��Ǧ�1#��.ve $�)��NC ��F_,�v�b�4�T��ʊG���	��4�~p^,�E#����	�����'��#-LV�����4�;b���z�w�=��'����X޹A�~�~c�R9f4N���>��,�ï��A�p��v�-����G�1"�s_;)���ڽ��h>Y��'f�Ej�ۖޯ��{�1�8Lʳzd�>�z��{2�*�,��1c�GW�9}E�_4�Y�M��6,����[�0�	�A�n�q��v���?�_�@
�V�ؔKf��v?	�f�.0��=x�t�w���@ۜ�i�=�+�������4��"9fV���ܦ˚!�v{�31� o�^=Ͷ�=���5I!��t�Ƹ��f�+���r����g��Oz{by�\����JYu;Z���(���@���Z����hl��%F���A'e���#��{���5+��#����ì!5/,���q�X�Wv��)���k������r��(M(Q����9�$�#���^�}60bHfIj�&^�1ڲ��!���yW��Ĉft�'/�	=�{cpehе^4o��|&,fVp�mtV�&n	�cF(v��`Y3�Ky�E�|^�!0|���d���g~e���[("����E���t@^I}>D�k}O0�X�V�<=���Z�Ʒ�
�I�c.J=Zr��e$���]���K��?�la����`����'�M��0��'<?��4����@[ȗ�J"��>��K�qn)�K���kC�D+D��74!Ƈ��G�$�7z��y&t�:j�"���G���nO�;�:�i����o�.7a���y������[?͵���w�����I�[ʹs2�yCv�w�����(+78��!����~�H1�@���8���D�T>�-F�V{�8�8̛�)�i{�xe�Ȍ�4O�������S�*�яr��!��~mm���&5ѐ���gE��>��T9�q!���b6�I曍������rM@y���wV}�0jZ�<G����6�.�X����=NP����CF,�*���p�Ud������oػ.w�8���\Nw�.�����ź�%�c&�7`���P>.�\w�N��w�%x�0h��]��� ���F�V�M���Ҟ�ߥU�J�0���#��/���{F{6݁`<���b��/(!N`�ݟ�k�YP��������*�#�<E|� �S��&7�U=I_�������(�l`xұp��Y�А* }��rQ���gY_]��3�t�_�F�`x~����d_��IzV�;�v����?[{ۗ�!��Bx8O֋��65���������E�^-��%_��z=3o�͙9��i�B[���m��G�2�Zu�/�r?�"w⏔'��1�ޤ8�~�!�=��g�����A��`m���s0��U|�ƈ�g��Y���tkW�4@Xç���;4�=��r�Jl �˩
�ϔ?�{��2̔�v�m�ⓗ�`�8��o6�86�$RT�6G�UVCʚ�#^����r�r��� �_�__,���˩3#*|b�]�����Q��>�B��$��F�M��`a��L82�yiބ����uJ�<'8g�>Q����L�e#�vU�6�oJ�֥�>����o}����_�F����1d�]�?���um��ۣ��<�r͟�������P�'���b��$Y�{��/���)0�a�7t@N�34�{exO�Qv��Wn|�/!�O����%F\/�������Fk�"�ϯv����5���pre�N���߼�;�^��4�R��0��	���0�a�,#�)&�%ց�h��g�_DJ{�f������UyC,��r_4�r{`k;(��qen�C�ѻ��t���6��5I�A�4����12�`��!���c��̊�|�����f�,]I����NPi_����hh��$�Ⱥ�< ����4�?���qT _��,K���5��A_,�sp�]�˒�pxr��~20���L��f�4sh��9�^~��h�dҰ2��[�`����9�G�ia�ku��G����ݣ���6���=�='3.0����U�v��3�$3�T.J?۬2T�x[���ɱ�YY$��M��8
��*�s`o+�#� 
K���I���>����za��W�=miI�?H.�;:��ы�#�f�yR�~�{V{~���|�ukt� ���)r�@�g�g<��yʫ�63t�<R��[-&ɕ�)ٮ�+:%����d���U�h.����`��q�v�ډ�����Eè�Ghi�0c5�8[;�_����C�8�v�� k���^�w�fY����S�2s��I��5��	@��y�I��g�]�
S���d������30F~��O��O�s&r��M��ֱ��I�W�r��?�����sg�|"�n-~y��?��1O�:�R8'A�W���e{��±9�@\G�ᩳ��+í[��`Ɨ|B+50�aC�]��Pڳ���I��$�B�B$��`�r�cɹ^);c�_:[x�ּK�yұ��MA��;D��쑶��FJ�w��h=T��-�:�o���jO��]1���d3�բ��&(l���G����Յwt`#H�E��=%*�����hx��8��?e{R�{���U�X^G�fb���֞v)����Q4�R~��Ɓ�������݆�Sfª�ͳۂ�����fj�tv����|h��}�h���)��Z��P�H�1C���ў��\�+�{�բԪ�fqD�ѻ���F8�����q�oj��}>������֎�ʞ��]�j��| L<\d�j��Q�԰���d�S`��g�)������ �l���gѫj&�U��^��4:;�ː{޸aZ�������Z����W.]r���^�aF�����Ͽ��~]����ѠpcН�2r�hDxJ����[c׺�C�@�<�'���U�!7dg�j�nŉ�n��AЋ �5_J"~������"d������%d�����������/�*(�8:�����o�5G0�Ǝ��pK���w��������u�f���fkx)L��O|Z���ޞh���f�Mߙ��~��s|�]䓁���N��a(&������2��G�r���ˈ���bz���\K@<G���k{����8 v�^U���+�n���������LT�+�Y4�r�-����c�?���#�q���A�A�^:�� ~
�(v���|t>�W��x듯j{��^��oU�z{՜'�G�!��_���tš�H䤨G��	�Q/F��%����������R��B���Fr-:��v��C`�M0�X���n��ȝC�-;~�����V�R-�����O�c�j��1B�V`N����c;�|���	���{F�v�5+��ڋ�z�m���Ԯ���ʣL8L�OΗC�$F����W\v�F���{Ҟ!V�f����X���
�?Mw�h| y`Jw�ً����������,�3n_���p���^��ސ��<_|0�!^_# �  ��l���8����a��(�� f����M>#yمy���NY��CiϺ.eC����<����h&l��9����U=�SP�����d���_� �١ڟ��f{�!�É����}n�����M�줷����Ool~s,�����3m��`D��l�h��(�Q{���b�c90F�uߛ�l�D���������\��1�l��<��`�"�c^@J�=��������U�m��^��By���ji�>V�5L;�w�'�����3��xzJ��<��Is3M�?:w��[�a�;�7I���=.���*�G{��S}q�_+C_�1\l7���b�<gN�P��`d�X��blle�A��7 #)-7��=42� ��/�(���=;��</�ߘ3�����?N��cdeh`e���ऐ�,���b��@� ogW�O�����dl�ͤ�d�<s������R�RN�� N B�njhe�U{� 7�TE            x���ɒ���6��sZ����<$�C1#�n�I F1����̬��P/m�fݕ�ND��{��x���\��o�>��4����|����?f��):�1E���t�������O�~��[�8��0�Rӻ��B� :�ɷ)� f��A�o�p������g�����#L�	2���=[��J�(����NW�����|�74�V(��>[`|��J�	��YZ�;��������_k�����Hp^Mo�����cc�Q��4n}uB?q 2˴(�d�gi^���'R鼽LJ>g際ɱ~)�%����Nsg�� v�r��}��uj5�̲�ͫ��W{���( ��N�$(=�![c��a��jn6�<D b,�2�|IB.�y�E��U[���ρ�N6���Ow�l���4gI9���r0Y��:^���&�;�C(����!)i�	��U6��s�3�x^`���eJ{�Ϩ�j;C�m��!J��>Q� )ݼ�P�3�l�-�<p��i��bU|x��[]ô��)�27ye�7+�O!v%����we�_KϿ�/��2���n�Y䖬k�|��T��܍^?�>�;w��9���𕃢 �W����<���جqD)x���;neA��&|�TE�_�0!���8u^��e�5'�Hp��T��	��M� �pU�6�DqخK�&���f�7l�0����"��p�7���"����N��fsS�ޮE�b�"�殛L�i9_r?��܌m�������
R@Y�ݹu����<lVyr�֯E`2nS���eԒ��ay�T4��,�Hl+p&��:A21zm?�J��1j&�f=��?�n�{�v3�t���<�ټ����0���F�d�Ef2���HTH����"�r�����8NCP꼔Vvݨ�}Z@T��¹̀=ڐ��EDr+��Lm`fc#�U>Y�nQ�7�rD��?`���p�
ʪ��`W8���k#��#D�$^7�,w���r���}��V�t~�0a3��w�<����?\���	���FC��E�����-�|��.+ފE	��d�E��^u
�c���_^|vWOb�����Hw�t���:�-n�Ʃ���&�����l$-��L-8�g�&e%���1L"��R�����"�#��DyA��;4�F���HV�)��ցi�E磎�$�$Mg+f���b���~#��������� O�`Q0N�&I�����Կ0O��3e���*j�%آ��37W[؇�@�/�p �r�1U�����Y��#^��EY�bs����#{��"#�$��H:a��'s��}�{<����cٲ45	vR;e;y7�//�KHP��O/:o�����t��_z'��/��@��x��N��k���D8�y�@����Hu�~�=v8���\�z���`��Y��{��r�F���>�^H�V�+o�]�K_���-���N�]�����z��	9�sL����B�g˜�i�"�ZK�(߽���Ӑ�_D�:eP�:�*�y�CFڑ� e��2��FD[�EXF�;�.�E�*�lv�ٵv�ai�Emz�i-w8��U�*ZYtW�똂��e��~��1��ߤ�eb,U�r,�*>o��F�>z{y�-y>�~�l�O��;[� �xI�5*@��F�+L�M@���:��q�Du��4�8���3H�ᎭH+iKd��7� B&������z�L�!��Z]��l:�?(N��R�" 8�3�q�o�l#�NwKG����<u��.A�I ޓ���q�$6{�5�p4l�~a?�z��D��a��9��vk9��;�H6q�:�d�ww;�>�b��3
��p����{��C.�ҾO�����x�a���9@\u�⪻�x ����̒�f�G�V�"�t�Oe��>.(%W�:�iWOH����=��;:@�pS3j��==��C��A��7���Ι��:����Xo���Hk7���Bi�c��>�R�tk��]���)�}�b݃!Q*�}u��ݢp�F
:s���� Kc�H�/���R�"k��D}�n��g1't�tm��a��A�C�����%�a��P�I�;t+��b2_&��_M\��Kb	�#dЌW9i����y)g4,��[OX7�v��*��~:m��P���Q��0�MVqg9WC(�gZ���K�~lư����ӲՋn�G�̑�0b��L��i��{K`�f��$��r;[@������G����:;y;�]�L(O��^Ff��}ssk$nV��o�_!��)��k^gU�r����Հ�oA>�3�Z����\�Jto���nG9��ib���w�>�E�r\�{"K��noo&�A� ��_ADj�g�Jv�)��VS�z���{GCI����!�9��UVo�pP:
b���;.(�(����1E�H�B����j����T��)8������EQg���۸���,x6?�N��-�Ӿ�6J?���BZ$�����q��t�@�u���9PiF+�٥$N
s:�`�ɹ���P0��5�t^��o��x�E>8��Y�1���پ"�s�$Өw�K>i�e�Hx���֩_�F���e�	����쬄n�?��c�)&�0M�L��Y�"�VyJ_���NZ��_���<�L�me���<klS��?t�@wWq�njb|�ҭm�_т��ѻ���<QН�#Ji��6������*K�C�mjD���|L-�&r:�D�ib��B^�����wQ�'��bX`��~�Êƈ'�e������a�s=?���}��D#Se��!��P�U���A�t���|Y���[����q��]�� Rq�ّײ!��pub����5�����ғ�q%{��]n�����a�����fSS�^�L�K���u���9��\�:�`���t��_���O�kȷ��Oo�ōǶZ2_����B0Q;?��-ꯢu���D;>��g��t��ޅ0��ζ-rz[orR�.?�`Q纼�����ܢ����48��ui;e�y��$2�Y�&Na������_q3�$�1�;�[�b�`�|�`,	���� �!�pq��(|P���vG���}��0�I[��!x�N����ƭ�J��-��@�$����O[�rb��C(G���b�Yfj1[��*���w���e~�T�e�_��`�Q�z��@�q����l���u	)*�?����H��Ebq�1�������;��*���U��b�������q�
�#/{���ȕ�����5���I*2�r�g�{p��' �"O{5�o@�e�4?�rf
������	�v
��#�. x�r�eI)�X����U� �쯊��/�P�����**{�]z-H���!3�Qd�d�ӓ`޵��#X��KD�Ny͹��Q�w�t޳G�~���`��X��Vp��B�W����8�+����י�j��0w�J�	��E�4���0��GH};�ؚ���zv��(�v-�|��9���i2�� ��{B�	b;UM�h����x�Ȃh�n^�"�Nw#bZG}���v��pH�W\��-��{(����`E��N��3ڟ9��iQ����K����ni��f�-K:�85+Ø��(�]X�b5���N��+�`��J���c2[�# �,?܁������ȝ���@�^~��������p��g{V�X�~��*R��rm������7|w���Vn4ZL�='���)�j�����r}�����|.�_��RuG���>n�%\�_�5(~H q:�뵻�O���{���Iʼ㨑n���|􀚛c�����Z����)�m��δ帛0R��=�.��2r!w|!k�Y;�}��n :m��i�t�{���%na���4���E��X��6�8s��<oG;��UtW�Z�g����׷��;'KϿ��;��|X��i^v����P���W��x�aȂ���ⱐN���S-Y�Nӄ�a�����l^�¡���28\���0J���``d�ĝ� 泓X!%��s̖���aɱ�P������}���b��d�Bۖ~�}�m`������3^��2    �՟T�\���{���Ot��o�vW�@��p_�m	�)�7�mdp�c��Ҷaƻ@�S�b�te�����q=k�=s�*��)�.Ä>R���$նw4k�B8�,��CZ������2\-O��BmeÕf!'�6F~\9��v���&�L��P'�m���.�yOZ$1g�SK�V��lv9���w}�8����}�(+�A ��/��uɟyNv��~n�K6���&Pc���$����{��e\����/��m^S�E����s��ŧ&�3�@]@i�MDC�ck=9����3z���[v^�;�~@o�S�&�܎s?�8Z~x�a}ueE����|]]h^�_;���o`!��9�ʚ�u�:M��_�޻r�����}ݵ���̣�B\�[�
�u�ƛ�vy	������/R���~ESK���$.�0����&AV�ݿ�<����W/�dϹ�y��xk�}�ڏv���k�đ�)�ERpwaݱq��mk't�r�z+����kdfop�&��Ý*pb0R�/�f��Ә��89�V}�9x���O�(�Х��[�ι�eq�!��z�˫�im�W�h	F$,8<�A�OlްLA'Q�;�\f���z��Z�#����Ex2�Gc��-��m����B���B���`�<-�\d��-{\��Yl-�-�8��ɬ�*Ƣet���27���0��b�:�݌�F�"ȼ�.�7�sC�T����M�n�ӑ�"��P��֨�J:\���~�@���dp2��&�>��A�c4�s���gu��#B鑇�G��`�N�1��~�싑�O
�j�r�[�Q�l���R��D}G�����쯥3P���r6���N/�)��~L���XjR�ʀ��O��ѿ��^�Z1Sf!N��n���É#w����c`�����qqp�ORԣ�z�(QO5�,�.���u�>_dpr��:��l�'֨���A���{�d�y��H`l��s8[��SV#����i�C�R�� ����W��Y�A��}r~`O�\4�|��4<)���I�_��E3VN�_�Oo�����o�DqB�n�����˜�#v���q4�x�M���ח��j2p��sGOᔵ����i���ֽyT��분��OE��7_�j��� �_D�+����Bޭ�߹KX�J}y�6����X��"T-%���8.���c�Ԅ���T�?�u�E�K��.��ݹ���ܝ<[+���}�b���H7)n���P�����pd� �A?}�I�)��m.
��
��"�ҧw�ߟA� j���N���1��s���Y�2H��
�
>�4���(ɕ؀��m8���`�P�Ӛi�[`Ǡ�`?Jπ��Y8|}����%�	�(}�m?����G���֚�!�#[|�\]����p�.��Yx7-[�.�V�p��A���� �|vJ�v�m�p�B>i���WW3:'">X�3�2��q��q��8M��� �Kp�ci��F)^���V�'\�E��Λ�w5 �:���&}�_O&W=��0��U�UcR]c�5��p���U��c��&��&�|Nƛ�mw���-:�?�b(�Ԣ1Tw��C+訳'��\4����Z6�����ty�,��׼L���`�˖��Q���=�,ia]o�S���C��1�c鷉��(\>�ڛ�7�����L�E}9u\)'���5���U��7�YE��6��e�M��8T>I����R�.z�ݴ�RM}��T��"!��~���+WÁ�fDq��ݓ!,ٗut�7u'.5;US����b������g�ǌ�a�		�f��!�`��&�����쁛��U��á���'��ѤU����G)����V�9�l�]�J�$�/��d��?��wZ��H]"|~Qut*��
'���?�mFO�W|ɖ\˭�b%��C�qb���%R>�9,�d��>���޿*������� asG,P�l��'��|B�e��d�ivN�ͅ�`�@©=��Ü0�Iz�J�����D<��B>�sp4%�6<c�3��׋^^<���s���$�#�[�n�ع-J�.�8��"wtE�e�n���?��*PlId���FQQV�AsnLz݃m��6������(����l�@W�U����<�w���X����|�,�~\����<���ۣ8�A���Nc��Y�7��I@�O�����Y��]V�n+�x��Xw��sW^^��k���+ln��6_����`�ss�b9U 6�L��]6��������1x(��l7�b=�g��/� �F���o����H��I�x��Fn��yCo�$�}�`��I�ˠѱ���[,ȧ�k��a�����Y���2K�}��`v�Q�r���X��n����/tp��G���h0�Xօyz2l��P��e*a��ի���v��4wTR'x�cTP�F�,V�`�$�[p���0q�.="wh�J�-���O�bJ����M����)��F�O���t��`���.2�'��z�2� �=jn����qD��b�%�x�(�tK���k�� ��N�&�����d��$�����U۷�e2�)�E��H��T?�s$��!W@�I����G�L=�R��P�o<�ᶷ'Ʌ���x�����~~H�~�a��ٹj���ӹ;"��]$�V��;��Ȃm5��WG����[[N��|*�8{2-��%���*���f��M��5RÃ���ex�k��	�b/�i�ζp��}^�8�GNb��C��6UP������^
�ܱw��e��AP��IN����S|m濿���5�.]�0�f�����#�9�����܋Osu�`�V����v�=l���§�����C�A��>�¢i��:[T�|��I�b/��������|6�`��qM���.~�H��I˯8^#I<A�v^L��2��2I�I���s��f&�I��W3�'���X�T'	Y�7�Rp���V�Q��VA��������	�M~�O�v7E���	�G��Y�kH��%h�o�S�Hg�F��7)bT�*���*�&_E��5�l���;<r� {�Q���3��!�i������@Y	� D�w���On�y��[�$�����D�=|G=��uFr�I��}eG�:�����́[�|ʔ�)����a�{gL:���8�;P��v��q��[x3_d�Ur���mtղ��yzA����������7&yT���+��o`ys�?QU��q;o�,��*V�EĿ�-5��5� Ɏ^2_̮OJ@R�	W�& Ca�����v1�I<��ӿ̥Q?�ih��6�j[�%��w:��H��ŅCJ¢up�B�Z���� �	c�7����G�ג�1�����1L���R��EpB��"\B�x�a�r�M�pٖ���y�<k��T��E5��4Y
��Y|����k庿 ��㧳r5]zi~E����&G�'C���j�v��G�g	��{h�1H&w/��I�k�ɫ0�fAȹS[�J��J�g]��W����|��'�mX,t�����'cg��&�
�o!M���H���5w�ί�0̀���{�<6Bu�1����NF��b�6v�Lw�?�F]L���aS<�ۉQ/K�Ln.C�4�w��)��T���k^_{�g����)?���8�Lw��h7��2Z\��b��)����A�5� �x�?T�O�>fj_*�fD�R͏���D���݁��OwsI���_����sgާD:��ڈ@�-��!C���*�Ȓ��W�c��ta�=��<���>P�L��03347�VHZ�z
S��*�({������:����sq3������Q�}����-Z{n�D�O3��.�?ZG_�{s�h6���:Aľ�{��c�F��Jݧ���d��
X��q�ht��.[w���Fa�R�#���8gg�4avnY����Ө��Cq8v9`�i�Z��u~�˫c*Q��,��U�����g�apKc^%���0ny݄    ��c��n��*�)�J�׭�GsX��iaj5��\��e��`dAd{nwY	�X ��n�I@�҄��A����V�a�!�Y�^�������I�Ij����:��$�8��j#�L.��qT��^����b����I
��� +w��t���R��G��ڣ"Ǿ�YY��R{B��������� �je`��\��}��ؘVT�	��A&���"�6��,lK�%���D��Z����j�uϜ�X���cY�_f��L���5��\u�(������|{P,���ȏ��A ��4�8+܉���{DE>��E�݉�o�\Nx����Q䶓q��Oz�ΦFqW��'j?i��r0��aõ��Ū�������	�H4g64�ߘ����+�7g�A�i|�xB�b��&j�, ��Pa)�Q��J{�6�a���Td��M�./�g���Ʃ�5�����*n�PةЪ�ї-y��5��'uvJ;�a���n�>���~R�u�c!�ō�S� �4M*��#����C2�94�����:-�8xfR��@VN��ϲ<��G�+���>4�yJ�Ҫ?;i�q�Z��NA�.&S�d���9Ƭ���E��G]dx�Hn&�U�?�`)n������VwPNXcg^/�)�~�U�@�A_�3I���7�;\���ER\��"���<��ؠ�`�+"T�;���v��pC#�������QNt?�CI�B:�����e/Ak���V�^b*Nμ���M�4np�_
R#*�����]�N�i�[x$~7���*�`qa���F7��V�NP�O����dS�q�����΅��V��w�`x�+�R�̢;|=�(���	X�(p6�T;=������@(AB�pq���Y.ZX������{]�Ԇ�S(�h�3�?�����sz'(�F�(�ak*?�K������D�Kg�T<�to�&�[����H���4��7[�,�P�<�m(���w�tpN�+�/���1���	l%Ȳ��y�q��M�MҜ����v�E��BŃ�{>c7N�e��`ݡ�-L�]F/��`)�dUF/D�®���㍈�׎=Գ��
���pfInn^�;N���{6��kt˟��%H��o����uf�0�X���º���$�B��.��>�O\�����yyq��noR��+2�n;�%�ӑ�9ق�"�s���'�i�"{$�6xb�X{����pP��>�ܠ��`��JI������5�	{x��`�s}�7[�b�g�]�Tm>�X7}+��l�]"�K�*i���������T�X:�E��m9�����G��{gh�)��by����f칞ܶ:k����u�YG4�ѷ[A������=�&H�!���r��H�n+����ѿ���M���b�=5\�{Jr�y��/�<�o��P�ά�)0W)�X��G��b��Q�:ւݷX� ֌o�H���/I���6��\=�K�|��e�g���ڎj%����<O-��w�]v�𣃪��?���\�,*r�)�����a`M�2�8s�7W	x�e�~�A5�s�bx�����}��i�*Q��L��+�����N�sB��nC-7�}mzIk�;� 3�G#8U��k�%J5��p�p�n�Zi�[�a����v�"�������;��5��r��y���Z�*�җ�������^�:jGfyMAe�Z�)�%D��A��%�qӺ�4����s��?���@?��g�d�H8�<��B�`Ɍ��pM�s�q�9�Ir�l��Ґ-���2o��d��H���c@�Ý{��
7TԦ�/k9�AR�w5���@�2�5������&���u#|~)Lc��9d�`bt��z���%�aR��/v�9ۏ6��R^N�<�6�$�dz��H�R�f��eOy8�R��=?�2f��;�	��y�qZZ�e8<�3#9�������m�E��'��q�ѳB�Ҿ4u!%�̓�pǳ}7�0��� �93
���D�3�"�gA�B)���FYDO��� ��X���ja�kT�������j�,ܑ�@�zW~�z���ca�������tdq��w+b�b�-�9�\�A1��\�6�Z���-���ݘQ�B�4&	��r�����>wNE�a>�`ջ�A� ;n[���&7���w�vKɲ���G��00�\1w�U9>'���i�1ן"3@��_Ek�	�\��>:^no�g��3�(ߔև��+���V���zu].(Tc��޺�C	V�c����Y�����	%��oŮ��i���$�����XiQ��p���7N��X��6�N6��,uΓ~�vM�Ƶ�>(}�H�Un�͗U��B���Yj�O��y�v�N{�矸��?k�����ܚ���01҆3}%�Qt���M\/��ns>��!��d,z����<6�(�V�),���b�ԙ;W�6�#F(a�/�������8�'Cv�G$��!���%�>/7V��F3�o#��=I���~���b�����U)�ґ��Ռ~tT�7	*2���;�O|�����'�ƌWӕ�R5��쟯q�V)��*�`��'�k�m4&n�,���Z?I�F�}~�P�۪�
x1�~+�RO�w�����bv3�XH|�{��p"��;3_nk|z�T��)l��O��cr�7�}�����c��aq"�#��e#�;�x<����G�=��lR\������GC�Q7��F+���3ED*l�>��c�ehʆ��h���W`h��6��$�^^�U���\7e�2v'a��?�u�0��i��x��ލ�`�1�����'p�+a��A�95F�L�kт�-�n<ai��"{s��7�~��;lr��ePK����y9��t7���)���~5��swޓ��6� ��$�.T�Fr�����.�5=uV���%'f�j}�m��ip�dy��
\��F�^�Ǔ��LApQyդ�xQ��`WϨ_-�C'=��R��T�U��q�x!l@�[\VS�\6x��Q��*���VOU��#�<m<6��< 3� *���^p���=H�t����?:�w�!ǜ;j&�b.�;��<�4L�w0��&z��8�l�!����|r\�x{�7�1�}ф�W�R��^9h�}���:-�_.}+y��bē^�hBŝ���@C y�b^�)�)�0PU^���c�l������������ر�>����q[�"��$j
۔e�$V��@�G��܊]��I��	�^�}�A1L���;�,S�^����ë�᳼LD;
�-ȑv^�z+.�������u��$A���5�a_�{B�����q��S_�M�R�݄'�i��7��Ě��Z�}�#��I�cu�]	�?�b�ӓ�X<�%C��6���`���q�&�I
��|��zW�8����GC�p�r�FZنG��1ބ�ϝ4���rO�x/7��]0��ȩ^G&,�KT��GqN�FX���6�-Zy7g#�>+��Nd}�=�%����չ1`��U���;7zS��Ԁ���=x�Ż33ԑ����ԙ��BB�r����]����R���[H[Kq���� ��Ew��I@2�v�5��Bl�P�)8B����!9JJ� ;����Z58U�������YF����jQbd����xi\�)O)���,�+l� �-B�*�a7de���>5����E��Ȇ�K�lY;5�M�E)�s�R����oo|y��Cv����M��`���U?��?���C�X'=<�AB?���E؟L����\���ڲo1�f�kտ34�#Z��L������ܴ��ފ\��U"�2�m�[���W49H��N����k�0�/"��碍��Q��,�Jr��ig9M��j��kWԼBst��n��O�����|��,�d����Hށ,�`J���a��<y��1酅�g�M�[�"~9}����թ�����ՠn����WRjr$s2uX %1r�fLV:��`�.Uvؾ��q)�=����ZMI�Q�爿ᶩ�����m�^�m�2��w�b��O�l���ҙ~z���ۓ�܇~�ٗ`���# =	  �#G7���lv�VX��Q�F��8�X;��$�s�9|���J?��v$7�瀘��f�Vr����Z���6?I��|�"<��y�:��I8ze�]�T����	N��N�o�e�xED�����R�wϰ��;,�sJϸ�>՝꾗9<�������m��g
&�I�	E�,ѣ9�<�=عM�HT����q)�=�u��d�-d��x�n����	N���c</��N�VTŭ�,1�%;�[�q����q�'3�7��4�uk�v��n���fw���������W2�ʑ���}2��C|�����H��}Hѐӄ�7u��6ZJ���hƯo��\P��+p�'H����j�ܒ��5�m�������(�ɸ#R�j��Z4\���X���v�ֱѢ���ΰb�]���dd�ޜ����x��|���1���`qf���/"�A3x�������ԶI=��/;�3k�; i\�R��)޲�jc���\E=���&�hrꆢ�n0��DOF���xy���Ȑx��Zhp9��@k�H��m�ny���><���7$�v�bj����=,,�=�7�2��ʈ�N*Un��9Ʀ���+sی�}a-�Ӈ�2,�PK2��W��i����g���'l�_eD�n�t����r�����~�Y\5�lΦY�s�3�wBF�\�Vuљ]��8:��zƿ��t�rd!��$��|����:��L3�'���{.��/G
�Q7i�����2��N:+���]��F��]��%�3ڏkG/v���{���I���'D��4ϙ��e�H�4[8�s��@~]���������$Ҵ7x�a�u���{����0g����~�+pȃ�O���S��2o���IK��4D���$ͳ3�O���5G	a�q�ǹ�\����>
n�I0�ryj��if0<����@���|y*x��X��..PK��F����3��KAq�W|]���p�`�:�����+��E$m��<��t\�^�l�n��%;��'���v0���7���3�� �J�i�L��q����0^���؜Nppù��jd���i�. �����Yjf�
VMyR\v�x��p��<�DQZ����}�vNO皬�NT�ǳ�L�<��}��	ɲpp+����ݭ����w�V�~Ufk���`}�����S���Yǀ�n� �:�7�md�[�Ѹ���pk/O����;T$!�/2|:[_3���Q�&w1к�e�_�CGɒ�p���A4��悯��UX�6�͓Ad��=O��
����U�r�q1�0�ϞM�
a�;20w=Mq�����O�Fqc�zp���E;qGB��Nf�.P뼔~���Fkn�I�P�2[�"lPL�iR�~��s�E 1�ѿW��i
�ƾt&���s����6+�`Q�=Ci�X}�"8��$�cx��u��V+^��Y�����LI��h�%�������6�����N���~~!2����s�ot��ﰿ��w���a�sB��yI�[��V�u���������;��L���9��1lN���;N���OB�|� ϐ��ȳ��O�2Mk��B��Z����~D���^gBǶE����Gݹ`���~�o����@��Wk��3ȿOާ� (�~}�b�,�����+4	iJ!9����A�?;'��df���S�%�S�o㵠hk~��:�OV�γ��������go,7��qkJ������'�_n&+j�Q�'�Fa��w����խʽ}}-џ���z������;va���,��X�PM "	�7o{�9�<�fr��7�YIQ�Ji��O��}�n�쏎�	�C�Ə�Biݖ�����~���;|��ҹ��w��S&��y�Q"��7b����Q\i��QC:�[�0��]W����6����3���/�(m����F���O��? �{����O?�-��I���S����{hE��2X��~�VU(��t�g��?����+�;���3�	� ������!3��Da���;G��[Rl�m��B����@�cw��"�@f������ዿQ���3�!��5m���N񀓭�q������2��N��Z�r��(���t�C��.O�͉�eF�p�v�LT����4G�(�b�����\���f (6}��+;͆?��4������V�f������8!R*�<~�4y�Ӻ[�dF1�奓^t�L�)2�"��FL��`�=f)k Ϊ|��_���������<y�S�(����VB��`�{��\��������oG����<�.�j���p��.5�~���E~��*���:E0��On����?���'N��F�����������W      6   �   x����0	����0��p��ML���KU0�4�4b45�3 N3mhdad���Y�xzfx���p��X�Z(�[�X����Z�s��$s�z���FU���eF�p����E@���4.{��M���֘p��qr��qqq �*2�         �  x���۲�H���)x�Lќ�ZA���(��V�( ��S�ɞ������ſh>��n��}����8�5�&��c����|J{ Q/H_x�/rP�yA����֦�:����W���(�� �����B�s,��y��8�9A�%U�_���Zi�����p蕝  E�13��ь��'P� ԡ�K̴U�w�wď�0��Kɺ�^�z\ī��=k�_z;�� �aI�%�oub��'16 ���'9"�rZwZ�VFxVQ�m�}��輢�[�y��M�4���F7�k�:���1��#����sL��V4���㳝�>�V9^�e^�ǬԂa�T|�����Y(/; ʄ����蜎�&�G��0 ]dj~署��f�,���)�H��B�WYq�ڍ�38IaqY76ԋS�m��Y�7�Q�$��&U_O����n�0m<E,��u��D�dc��s�����e7M����(?A�僶G��n���}��;O��Gsa|��XY^�C(8�H��M�"fp��u7�{y7;jԕ�,�n c�I�e�&�R��^NY�I��}An�bu[�@���f(�=13���ڮ����$��.�����r%����</8�^v���M���Q�8���0����)�fH����pr�<z�����f���:��Ήw�w��hƛ�-Gڼ�+q���}Ђ���t^��9~�^�Ը:E��)�Q��h.Zphb������a
���k4���*            x���ɮ�Ȓ6��~����+��HժI�� �EԆ�<����-�D�*���$	�g����g�6��(�d�3ɬ��=��^L}4����ɰ�j�����4��1�G�t ��+<���?w�?w����=���7��������������� �������:=����ݫ,�~d��VQ�uM�l�����?߰���?��o�,9��� �E�KL��Ńm�liK�}\�~�M(��iSÀ+I۰�A��|�(��g��wz�l�'��/**�<�j�:Nյ�o�����i3�ٲXf®�{p�3y�\$�4�8�eܗ��h�s\ʒ1��K�Q'K˜�VU�k��!�:��N�[�WԮ�NJnz�C��&6Nt������i�A���l�ߓ>Wb{@���Pj�M��L�%!�1�a�oQڒ��~@��1pI�S#��z@��صW�@o!���Pt7�	4P���!k+��(M:dPڝ
׉I�A�"��& >��6�6���s����N�:����Dz}(���,�Q���+�G>ݵ����A}���p���Ƨ�A +�/#�©��=HV=!~_X|�̧����g>�&��yF����-FsT���/�TLp��Wvu�Y��f���/��\�������'p�����j(���em���6B|O��S�@�ι��`��Y2��'h�{j���{ ������~�Q���8cP��b������ʪ���3qf����%XZm}��4����-��U������4�b�hw���ٹuж��H�^�A�u�����\8�� )�3�����=�B��1�,���#dB��`^�j�?AQw���q����4N�-��'j~�� Ŕ�V�`�O����A-.�J�B=���Ɏ��--���� %p�	G.�d�*�->���K���.$��}��U���A���s���u�.����֞��c��(Z�+X;9=�X��;��k��h�6(�;~%��|?Uh)���5�l��6͕f�P�{l���(���M��s	g�Kg�RaC1]Yꂺ��V��4LPg�d�k�<�^��?`�zjw��)������Pʁ?��U�b��G/���T�^*�t8�����j���ҷ[�ѯ�������mɩ+�g�EN�Z��-�aPhk��E�����_B��1g�n���Ij��j�Z}S�
�������H^�D�*r
�.��Z3��a#�K��#ox�]����D��!Q����k�J�͉���24�WM�Y±]4�RTE�ṵe�}���,/�+d<-؋��M��H�s���5Ԥ�+�Ǉ$�[S8�؄\xl�0��>^�Y/f���"c��|{_vU�C2/�������x5d���.�]w?]v7���K�`m� ��Oz�0{��q,�{�h�Z��\���W��_f3��E�9���w��x��{�0M ����}'��4 ���S���
n�=a�4y����1� 0G�;g���Bf��k���'���o|������mM�J*ȍ�����{~����.n�z?�>���F%��_��y�iH=(���&{��v�N�L��z�&޶��y�����K-���G�ĿgWi{��ѕ�RN٦Š�C�G����6ru��פv�m��.�b�E�2��l���-!Lk?�R�A�������yZ8�����nma��c�����Vkt8�aK�zU����; ��4�����4�������^���<GN���I�g=�`��|��a�v �/����НҼ�у��)I�t�fn(�O���ᾜ�czf�ޤ�m��贙�tꡌ|\g��y{�qQź���7t8������&�ӧ���0�����1�K|��{�e{i��u䉷���>��:�6+��e��V��N������O#�4�����_rV�iչs�kz�����E�b������	���#��v��o܆A���CD*v�zۦ�e�ܮ�= H=b�
ũk�dM���W��i�2��^������>��5�]���x��F���'���¿�!r���.Vl��q��S}���)0�(������1���<��b�u�8��	?��$��˳C�]ش��8PS�~�7:���i��4ʊ������������3���N��+����pL�-�uo]���8�'���Z3��.8�%ot)*J;����}(塝��1�B�^�<XW�5%��8����mp����S�ő����u��څ�̤�#+��l�=�0|���Ss_�I����7?���?)\�C�"��"45�"��)yՓ�	��b�C3��k�".������Gx{�/\�)m�*.���Tk�0ّ���'?��o+�t]�TȤ�RZ��ao'�0�P#@����it<H����&�,z�+[�)⩛b���SUB���D�&����[�vn������]:���q�*p;(Y��.;b� �)�'_��VK햴�=�e�y���I�Ȟ��x��awb��pA��V�����O�.�ܖG4𥉉�$��|�n��\����r����Ik<����Г��(�+}���m��=^�=��U��${�?�_����"ވ�N:��5��
�ڼ���b�и��]��Jt䙻����)�:��8��x�v4���b��qz��l�Ή��p�1+��1g�'�N� x$�v����0 ��%����ha�.<
\�\@䬒�����i}:eƧ�� �&	2TP��_��Pԡ��㵿_��<����q�������"}��感D�n���ͫ_���K����;0gD�b�\�6���^�,�;VmrJ$EN��M���f��8�]����Z��T���k/)o���150+⩐�B%�ң�˴��W���ZD��m��g�����q�Iw���P^+y��C�M}C��h����h�ގV��
!���*	?�0���R��Φ��}����aD��5�h�+O�2�+N����ڧ[OyA
E��u�D�$��.q����̓bH�������e<Y�O�� ���񘉧�wdv�����z���_B�Z��2���XҏX�!��cڈ�R��q��F�5���//�&z�ą�u��4�K}��=��M�n�"]@�?%=��p�Ȫ2�2^��n���l��tzD��WE��sM�6 F���c-�Qc����@���*z.��9g��M碙g4R��UԉM��#���S�9�e ըx�V��9j��� )��a�C�Ս;?~�6�5���5D��R�B�7�����6�ӡ�+��ӕ �O�{�O��T1�Ոn�B��U0��){�~)}��Lo���O��:(����z0mle�4�mP)���^��i(��R��y�7�Z5�+jsc�`r��7:���G엶�Żc�@o���nb��'��=���q����H�ִ}n�H���;�Ś�+���ż��>y�l?I�$����]��o�&��c���[���O�l������F�Cvg�������f�ۅj��dHn��`�=J�^��|d�ůw�<+���ME�����gJc�����s:*Z����~QM�M,!>�y����9�[�������(��PG
�8s�}��|�?@�-�!ֹ�鹟�2�Ң�����:jw�^�\夕 Bd]��N���>hl[Fr���:�w��l::�ϫY���N�$��:���շ���!@w!s�4�\*n��_/wJSg���^H�WK�wy�p��~�x^W�gs�w��G�FgNv�O��N�|eQ�Qe�r�@C+B����A��m�ȝ$χ�b�	��lwdOQ��j����^�/r�c%�O[�񛳷���of���݃�d�:����!a~H�h�[�~�q�j=��ñFl_��m��	���J�I��yF��U�LFX�h��n�v8�Կ��f��
�:�EH6�O`��!?I���������p��>5��y8"W7tE��^�)E�I���33m���ǴFL7��1�(1��6ɠ��4#���X{/�F	U��j�hdr+�Sav �    NH�3A���� V��r���L�њB����c�oQ�SU��!G�@^��y���j�7��le���WޡK*
.2��xt� v=Ⱥ*���.�a�r�v��g�?Fa�@y;��I����/�b��� 5�;9��&��������Q���4��Y����O?j+Ӏ'��٩�$����1�[� �S���?A/̴!������-5�T�wswu�hI��;�U�{2o�e���6��[����;ug��M6G�G1�w_%=N�^���iz�Mf/>[Y�b8� �m�b�Em��n��������$��Q������0�~�kÏ��%���q���*8f׏w]\֖��5ّ�-Of^�����ɱŚl����_|�MP����;U��mm1O��7\8��pn-0?�����ܴ�M�M�&x�/|��m��u�� G�i���-6�査5<�Ӻ��@�~6�%��m���:�޿]��J>HV	g�]ċ�=�ί'38�FG�3j���j!]{�-{�x&N=���(�T���.�$+M,�M��{��1��,o�[�a���������� �L�+�K�ǌJ�;�J���G�o�Z?:���]�AƯ��B	f'���g���	����YI�W�m��Ϸ����T�T���C�����0��q��I�����:UY�}��^\x�+�����:�6ǔ��ЋV�<�x�ŇzmO;Zy�%^��d"��nLGNW�&�M!�Ѣ��5����2@���.� :'nOq������7�!��	P��[���+��<>��/����=li��^v�����Y`�������9�-	`,���J<α�^���}�}��_�xM�o)�c�.T�(���y~����æ����ټ��zUA@�:3�8l�@O{��C��z������l���0��X�"����,SleIB�}����擐^��/��x�L=���	��x6k�F�	{c̅S��~o|8W|��ciS���y\%�$D1Y6<�>T����HQ�@D���G�l�֕�в��뾣J�
�w/t��9�W�d��t�����g�K���;vI���(���b�o�'D�Yl��j4Z��?H^Y��y]��\9�j�oU����+90�&�Y�O�[J9�"�SJV���/���d����[�eS��N!�W�hO)N�e���������@�~Dn���a�-?��O	�7v�O����f��D�#����7M��9]�s��*G����u3�E|�+�c�mf��E�A�/��;�Ȉ8���_q�?��!�V>%�h֮��xk��c�O��F��T�!�?п���NS.Ǭ�uSLyC�E�z1�G�r���8���e�`�p�#);��a�Q�m�f�)��h���+��+{5�r�Y�L,I�L��uWA%Q�w�Yٔ3�Ij�#ح�hǅ�y%<U}�����.�#�^�Xo�� �Z|�A^��:;��c��:�lHK(�����=���@ݵ�.-�;�)3��r'	��!�q&M;p���z|9����j�����~���*1�!�֋u�5/h�Uډ��ɚ{��P��9��J`ϊ��an9��f�"��2���VA�˺\s��TN�{������"՚;��cM���0��֖�_cd�q�;`��a("q�.&�=.���-��1��H����''�w%5������rÙ�s�nsf�&�dJ��ˡ���Z��V����^ ؔ��n�X�Ί�����ez��%0����u��k#�J��a`	lg*�(tY�H����u�'i�������ޅ0ݬ�N��f�n���f���4h���=��w��̽�&U�1O����>q��=���tֻ̜+�`k�i������^���W��U;��I`�X9�N��2���P&�>�{}����n{4<��h*��H�c�UFd6��k>�UV������ߠ�\g?*�y>��S���o+�O+Z`Ѝ[!���|,4�.��V�Ӌ3������㫿0����}ff��1�q!���s�"�F�>�2KIk�/[��R�m��_�/�#g���W�Js�y_ϟ��M݊?�C�U��T�:�c�$�2���w��	m����^AH(��]'�%�F��&y���M/�+��DU�;��uU����T���nf���=[}�C���}�ٜx�s��[�:�����^�Է���L'��hEr�� b/?�(���?�ў�Ѧ^t��T"C���q�^R�miF���
���#�m�Þ���!E��H4c!Q
kN�e�6�B�=�w����#�'�h��jHZK
��w�8��J���^��Fb'2iwOs	ow����+��<�]�.7��^D�6�H����֤H�N��])��OДۗ#�/�D�ة��O��p>���e�<.�]*��'��m�?�#��y��\_�⻟d�O*����C�\?�Kj?�٤T�1�����4x���!����z��.*c}H�k�9�Н�	�%2���.�'�� ��U�N���~2n(�V�.��+��9�r�$�dk�#��ݯj�AJ�%�8��A��T����^f�&�\�@��@�ڒ�.n�v�W��۔�Qܳ��:��'�䐛�������\���l�2ԝv�IVS��@�]���7�7�oV�h�2>3�!�"Nϣ`mɒT��'����/��P,���]Ah�m�BoLǓ�b��m.!3ل�>�vS�lRp���.N4��ǲ|'|gXV�I�02��pE,ԺC�����֎+���^Uy��|���TA�S�K�5ى��uHl*�%W�[zo΀3��.��ȍ�ʳ�p�����N-�	ю���OcL�
���)�1B��.�c)�e�H�1/�W�˗Լ�aA-�=�s}(����f}��`L\'���g���zɹ�����;�}�0º��&��\�J�����=U�4�f��JR`��Ӥ�	��q�\خ���e�^�L�!��_i��t�ʦ[�O�s�΃>L={Ց��Hk����UTm��n�����yɂ��wQq~*~�OX�L8��iJ펢N``1\Z�c�ā߼��f~9��o���b����&��ٿ��5�E,R�'�/���W�$��d�E*����I~�G�J3�$����o���$8;'W��o�]���I����x�Ď�{=�z�V���t�Z"Ѵ��~���cV�=��kuuN����^�)�K�=�+.�@%u��F?l���o�wL��5��r�xM$.�Bh���F�}2cG���o�[�pG/�V����U�y�pW�_�0��U��u��������_�-�T���G�}�GOOG�����S;��ԽZ� l�
W���K�Y�,���Q�;h���Ⱥ�cSۘ#WU�� |�7��="}2v�s��l�w}����\Ͽ[���^k(�m�_0���mM�����0'=C<ґvt��;�2��7Dc/�qA��q��,F�����<�?NS,���ub���cS�ϯ��&��WϨ��'ac?�5����/bJ\s��Ӛ�I���G��S�2o�CE]N��{�n�.�0|���.B���&�T|gVB�M����&��$+����XY7wf��Zs��<�W�ԉ��<�ҭ�#f��U���»�N!���X�;>D��4QX�n�ݓo��{���Z�9x���!�R�?m �xNM���̎�H�<�K����ĤO�z��X�d㌋�Â��[���U��h��ʑ(,.x��UV��{�b����#��ީ�ٍ��������w(s����c�L�O�Y�B��OUw�^����b	��*��@i�,q��jK�G'����a3e@�J8�/�Ŏ�%|�㼟��S��R���Bp$���m��'��Z������&�oٻRs��x�/S6�?
�����~d<�a9�}n8F-�<�I������W�Ju�~�9ݧ����?����6�N,J�Y��)��n
�!4^�m����46;(?�    �?9\k�ː���?	��V{�����tB���U��1B�!��o��ʫ��è������h��1��Xp���K
�Mh���@~������N�`�N�g�8�|\ʓ��V� 4d?t�dOA)���(�t��W���970خ�E��e""ru�:o(e�%�{��OJc�8��BH��}�!�N��<���l���W����:�blW��+N{��'��n�q�PNW������~}�^�"銆�[cX�A��?t�MQt5��N���t�o~m+���wN��h�([����޹�o� ��ɑ�󎵍�{�޶��y&dR�x��Q�ˁ��Jhs����( 7��S�-����7��� &�H�A�;&�f���R�nSPFlIw
&��x�����|��-h>%��疁�]YIΩ|��~7���+b 2w�[n<��&��� A�8��VPy�4�K���k �#�86���$�w�x%��]�IU��r=�5��M\��/�x��A(�w���]}7����u�\D�9�:�����\b~����߱��,!�D�0۷��Ǝ��W]奄���@O�w����L�U8$Fn��'"�q�3yL�Ì�w��;��@=J��{����|�v�lp�W�L���ŵ5�Y��?P#Z�S�kGU����ΏŉR;��w������?�=ۍ$�J�K���?�,d!%��q�p�Ho����LΜ�W������x?2�O��6l��o����)�D*��<���yG�M���1�@dQm�nz<�����_Î���kZ(}E�9zt����8��l_����ǭ���w>dw���6����d	�CtF,�����{�tӿ꾧)�w���:�'�d���<��9�qVdj}I�W��/9�콂%R��ɧ����Wĸm�]�B����cji���}��G���V|"���Q
Y���e������2ZN]O�C�P
[���[�)�b������iĈ���{i���.�����0��.c�x�	���Aٺ�׌�x���~!\|OJS�d�)������q��Y)3���!��ȴ��:5�Md[����-w����|�=������Q���	��r�dO=�GP9�V��@F��N���}U�A��1���1C��&;���O�Be�cC!%ý|O�*���MkJ1u�o�b����Ym��tDL9*���uZ�<"�)��wSq���[B�0���ܘ��Қ�&�53���������9�`lz�d�""�
���L�U i��z��x.�\�;׃��s�It����`G��%L7�}�r��7����2e ��Rr\.-w�ur��6��ּݬ��9��饾��F���é��C����X>%@/K��1�;�1i�t�@��3l��J������5���I�; :��R�?ie�j�8Z���Uә��}�c|�C������vr��tQ��y=|��������zp�?��Gz�F��=��B�_�K�i��՘Qʏ��n�ޤ��w{��p����v;zZ%����|��^?A�W��p��|#[f�]�`%�}ȷ\�F��X�4]d���~�G���O�]B�h���:�{��C������7�\�sd���̘$��KD2e��s�=x����٨�ۡwn��@��#�I�\-���������v<N\E�(̷3<�Ö"m�n6	ۂV��c&SC��G�`�-L�E��*\>��=��F�(�Dwcܰ� 'D����������@F�JH�P��O���Y`��Z���o/���u��q�P�D�]"���<t@ZB9[��b�J-|~��Mt��2���6��~����ctб���*ֈ���<�(�ԅ��r�\����>	��� �5yc���2�����kCh� �-?�<W�����x�%��.��R��卐�v�9mG�AlE�O����0���*stt��W9���A�q�1�u�Hh��$�O�����X�4M=�߭e�TK����I �*{���	��݃m!A�sxz+��)ّ��[^�'�6~:e���n�FT�@	\h�U���{Ƣ��ž�<����JN������b���!"����p���T��.�X�Q+o���9����D��/�h"����p��� �Nr��v\��%ze�C?��w��]���*w��LӥB%�8�{����R�\=ۛ�/���g?�����0��Eg)�"<��8��XH`]wl���o��=K��4� ������o�'��c~�\��*G�J(�'�[Q��y�?��Hy	���2�?Ԧ����w��[d���p���Ŵ����TOU����݉aH�	���v�� ��ғ&T��Q���Pn�۠45d��=- Ε�4�����Wc��9��<pMN�W7SeX�b���3ҟ[<��虜J�{�7,ہ�1�M���FۢZ^T�/����w���O�����畣�El��H@8t+nI�#��i�]���%+���u�
)7p"�cb���� ^E#:G�
)�Y7��Gg�Q��������՗��1��z���_�ζ�\�$�����M�<ȡ�7��.!NF�zXm��;�YEZmsMArb]I@����ԝ:tT��忧r�O5��8��3"y�R]>e���l�$sa�����P�+�	���e�V�p�3�m#�GX�vK�{v؋�I@ݝ���gLPW��f��W=�(G���lW�{d���䫻��N5�~�H���3��LthI�O94�戕����Y�j{j6;�L�^�x�t�ֻ����H<7:��,rR���%�d���S߉�|�E5."�q�ޡ�w��2����Ɯ��5��t�y����CD�5_�_�n�nSe�eF�k�یf�G�º�x+�ؿS���5��ۘsl�#��?)sL�6�Sh�����I�6���ŁQ�o�B��Z����f��P�������G�o�K��(g��#.�'	��o�n@��++;�41u]T�Yj��<�l�3��š4��9:m�'��т�.~�p�j��eE�s��U��+�r����~*�w��\�e�������M����i��P&7�8#�N�q����J?�w��RȔr�١��tT�;oL�>^�6��I��8��O�+ஹ}�ی��ۿ���a��Tq����hd#��7���+Ϟ0�~y=�����ϯ��!r�d�x@����Vu��� �o�T���<�EZDՆ��kD.�5b}�7bn���N�oE�%��uN�ŋ��G
�C�����{����h�tjj����B����>�.��^�z�M�v�॑���m>�,��m�L�Ԯ��.qq��d��3���ٛa*8���7
�, �c�=�{[���'?=�z��o��5�ƝN�0 ��k\г��~�&y��=t~����ʮu
�����
��(�tL�p?����n�^��w�؋��������<��c���3���h�Z��=l���A0n�'~��f�^W�FY�L؆�<Tpim���,�#�S����)�IUO&u�>�_�Y�� �58Ju�|�Z�R+���\p�/;E�1�ܸ�G���,�����<��ѵx�D��J��T�6-9�c��X�^��xJ>��6Ʃ:ܦ��ģ������r7Y�������?,�X�֪]��Z�19���1��9)	���ߕ�5dһz���x5��tcpИդ����[|���>�);<��o6 �D�۾>Zktf(�iYI�����&^q�^W�>K���_af?���O�h�i��m���U����|ڼ'���&�3c�s=��R��j��艞�o�������C~6��#���,�iZ-JU���!�ug��4?�<�>p_��p_|�mX�$��.�} ��Y�-���Տ���l_?�@_���"Rt'����.
�����a���؉��|�$<�%�#�5���F�����]C�F���w||����<�5%>�'�C%HuԑDN��5"���� CDw9-z�W    ����v��f>sCG��Im�A.��ct�|~'��~�Fp3)��`�ڻ��8�����I�Gkt�2��r͸<
���/��c%Ǥ���ӟ��>��8�M����xEO��=�D�s��K�����;�ү9&��e� e;�D�w6��}l��v�Z��˟H�;c�/��[�WWaX�ߵ`V�ɛ������=��������v�	����m,��;�m��+���W������+T�H�R��}�ݪ" >����`*&�������p�ؓZy���Z}�2ʨV��������X�5cvц��t���G�vXo��F�N��:��	%�S�t[jDbH����]A����Y�N� �l��\�����<v�u���$C�k�9�N#��̀�@)�7�:T�q�&��8���l�u�-'k��xlH;\PѸ:Ŏ�7��Z7������Κ'HͅHW� �v�D�
�Y�+����O�����Wb��<@��&��=]2=⎿��fm9�	{�,�{�dc��a��T]1��p��{�ڻ{� �^0r���l��$�����h�-����_v��¦�'����+���!< �j̞V|��0���S�N��,..	8�&�O����T�7��$�cRu^zP%��Ry�K�\7WE}:e^BN��oRP,]�������������T*gO�`�	�q�j!N�{3�
����}1�O��	�0"b�ݭ3>�k� �g���z��Z�ٗ��Cg�7'=���.�Z�Rp0�ׇ}/��G�,����� �Y��x����T���@����'�x	�����ٜ����䡘qo�N�&;���3�{�+d`f�d�dv���ؑ�h�^q$o1ĳ��&�Ep!Cf��2ũ���p�^��+MZC��Q t>�3��~e?��f �v�'�������A��������ߦ7Gp�����p���ny���˗cg��=W���� /g�/�b���'�C�x���n$kt�u�LƮ���sw����`� �����v��&��'t��E0�DM;q����r��2�p�Bt��k���"Oc��IlSu�b��Z�[b���Uqǋ��7��N�yw�����N�r\a�e9�����R�Dˈ����~I^_y��7ķ�����`}x�ަn������G����'+��Wי�댞�KT�{�5S�e�	��4⹛O�i<Ae�+�E�c�MC��࿾��	����oO���T�A���ѦԽ>�i��?[un�m3�ظ.�1�@W��_�'��u�$��erg��jKW�~;�D����]���ݝsb�?s��Z��s���ca滎���:�0��6��48� KV!�ywB�}���{m!,1�"������Y�>��^V4#��bT�Y��au�2��>������*��;��>���NWk�T{�Qz<�P�-�9BDۊ��['|gO��s/ݶ�;�uG����˚�35��/�uvn��2G!i}�w½Z/h�^��#{^�'^�jI(��$��ζZ�-�ɫ��%�����3�>�F>VLV����=y��~��t(�/:m����<)�@J�'�Y�O'��iG�D�!i��iP�W���쫌)�
��;Sw
��]�H	H�����(B���ߝ;!�'ә-qi��Hw���k��Z;������[��M�e
��5���
�C��ɭمX��`@��LC;"Q���?ʺ�F�0�9w�}ޡ�r����� �g4�pO�AZ��(�< o��8ɕܫ+���d�CV�)Y�V���Y���H�:OS�J<�I�~��z0 �mK�E�5�Y��6'���:�e��g�﵁��cF��{�Q�/G����G���)�p:�����1��߲C�{BsM������x^/:4wYв1 ���1lGձu��A�b/��_��W~o�ν�ć���͸)2B�F���w����r����0�k�ͫi��Ì��V��Z)��A>�0%cj�>�~�Vp�#,�r}�C�ٯ���YZ��:��#��D5Y������ >]���r�Qvx��[���:*V~
4��[�[�Gmr`��uwƨA��.�׋�knK���?�!�;�2vϥ��%V:��&
���w�
�(���u'~U3�J:j�~ٛ9��9�7��A��<�؄�mڏx��C�S��?���;�A^��,��s�';����#[�Z]�Xm�uny��6�β����v9v�e�韴���k����P
��� ,��4��W����͢��lٲ�CA��pJAt[�N�����փL*�.X���\��} ��A�z�!-�N��16���)�2��{���󗱔e	�Y��'G�%�����z�������=����Q�y]�N��)�pҦX�!����΂�#��ήT��`������H����!BX��!u+ҕ�L�=@���f��M�n���օ��f������ۛU�B7�EJv�|��V���VsJ3z%\˳���N�)��<~	9�\�Y\�H�B2p@ư�:�$#v�f�9����W��.׹�g��Fǟ��o�4��A�]Y�cT4H4@C=����ّ_�C2���P+��N��l����\S%�F��4�{�5�pب�J�{��|�p�-N8e,�i����,�����7�ߙ������?�<���<�WA��-��5��ّ��N�K�ug��� t	�9���OB~;;4�R܌A�w���.�Ϛ���7ٱs��$��yG�#;�(Ǫ��LF��Z>O�yw��e�'�p�6�V�n%�R,��7�1&�|���Yx~��kp���ˆHn�BjFE�&_��@wU|�NȺ�����~7/xz*,�t�n{n��C��7k^��-J���3_�q�-�����^9�Z1k�o�oYp�u�!���\ ���iK��u����N�{nϗ����ӄQ��w-p�
��T�vt����ο��>z�]SwsY�^�UBˎ�O���'	�g�fe�[��<1ܔ����le�H�4�d fϥ���V��a���+dJ��WV�)�w༰~�dq�հ߀�Ky��^�-w���jO�rA�����hrU����5|��n���!��NBDO� ����[�ι羪�AMk%Y����� `��Qf���Xi�yr��u�~�k[[�:���پJ�Y��0�ߡ�����n�Ǘf��YQ��_��{ö��R��5�p�A���a�=�\�U&{����{ �Q.�99�F@h�Υ���¸X.�cz-�j`\b�|dO�s���4ڗZy��/����؊�M��m�&r�vQVGE�YQ^���'Zv��$����_Rj|�ۗ8���+:*Ե^��:��z�~dyb$�Z�w5��"
��.�J7ڙ�^�>�"���MY���&�c����|7�
�s����O�{m�=`ZOf�r璝m`?�AO�0�d��1���5���p�?�ڡ!�Z�82��;I�ʱ\��/y|����"3��y5���`��u/7B'F5|���x��vt���-��k��" 3l�8�7q�|��O��͛������N��` u�!�u��F����Ŵη�[;����H��8���oh8���M1��`����<��];�9�-�az�p�D'H�G��2~�qm%��y����|G �E!��.�d�c����As��>贞�m�fgÇ����ά�A3jEY�!$��s��o�~��CL��y�,x�uLT�Ԣ@�K^���M��y?��X/��l.tuq�xL�r0�(�-kQ?{.����x$d*�l���p��W{FF�x��lҨS���N;�#t��L"�	���u�! B�z�O�PS� p����/�M�^���IT�/���9�Z��{�XGA؍Є�L�GXZ}a2_y�׮l���,,�1���IӁ8�1��p��U�?r�OJH�qv���I`�y����!I2��I�,�6m����t�I�<�@aɍ��/����/V�ǻ0,?\��W��8�U��O�Z+TQc�D�ߤdS��U �  �s���Q�?O*|D�u+�\���Z���/N��f%il%/g:�uO ��Y�k�4-���g��eM.㭑G(C�~���*�[thg��jߌ�@�-0��J̥/�/=�l���m�-3#��q��]�я��\n�� ��66p�hq#� Y͊���=a ��cg@��~�%�1�3��ޕ=�ܾ���?�{F�������yx���0�?}�l��8p�6O�3.7諆��n,Y��58��zj���doG�
}n�4�×��;�Wn���,]�;���o��:�O�m�Cٌw#�z�q>-p�����LX��@{�#r�֬�P�\�!���aZ;xF%LH&ũ�gf�zDW�v�b�hSq���^=y�(A?�aL���i�l۴��Y̨�nXM����x�0(;��o�~@b�,���5]�L�A|3-A����4�����n��q�����|���-�!f�6irNnsƍ=߮�j*�2
N1��~�&*~�
?)k�\�zˁ��/*��ۊg}#�k���x�T��俕;~@�{D����6VղJ�`D9�pĊ[�]�`����ʏ�`����S�bG��,+6���2"��|��}�YQ<�� �T��i�>�D�s��jy#���eÔΘ[5���׺�UI���fl���m��%��N��U�BŻ����)����u+ޚ����Ւ���0�A8\싂7�f���Y�u��ŭ��s����t��mD��������9_ě^�z������Bӵ�3L��sj���XW�G�fY�4�H��u"�j����[d˶@G����+�{��_t<ld�/\�~�>N�Vs�q ��pQ*��� ���'�h)NG�{�Lo���Hw�>��-��}� ·2�Adj�zb��4���:�os���s�f���	pYu��ee��h��[�qX�����6�8S�@C��_b�H�E��3u��>�(��33Z�g��h���xpI�{�[��Σ]<��f!�))���e�Y	��V��Q��qO��kW�ͳ?CH�)R����,?�an��dz��f�.�+�=MM�����\+�b?"U�4����gk��~�q�6<4�rw��iw�η��e\�$`F�_n��5j��SR�pQ��ð$��Zc��Y?�"]X����3�!������4��J���w߉;ۨ̕.,ʮW=8;�
<U:��Hq��!��v;�yr�-Zͽ��=`�c��*F��tO�w����{M���a���7ހ㥋�I��Ӵtz%���V��':�.-�dg�`��}�
�4���"N�F���ҭ6�(N_�*P��{����M}�=3�m�qz�r�M�L�3���]/��0^��9�R�a7�{'�XQh��8�峓����骿��e2F����F8��Ɗ�0��n�ڻ}[�?���G͎襝;J���G)�UK���<�D�^����JrP� �(Cr�'�Z���6� J��w��s�rה��0�,^^�n]=B��'�Wb�N¥F&ZJy����%��h�9j���#`��c�Of����Q����ٱ�-�9=��xS�'QTn����(I�_���~«|��K�\��eڻ��֦���*�����g�Ͳ-IuDŵ���/�;������Y�u�¢��-��b9�)*]�a��z"[����r*3L�`��;$9b-�ғ��y���ޭ�*WlW�LNj��29��E�:���w��' ���8Gh"��Z�����ӥ�&!f�3��t��Kj0��cȱô��!�.y��rc���x�"bн* �P{�5_�WRޝ�/:qh7y������[n����C?���tm�5�SCVW��9�10L#V#i�e��V?���S�5��������+�ϾC����nB��X?1݋�z������8-Lq����dW�ȮO�7�V�p�~d\�c�`r�r,�: �
���VU7�r⿆�6Y�q=B!��&:�����}#撚�e��32V%�^a#��O�/�϶�ɏجmmuEE�qh9�'D"�"�Ϊ�#j�䷛�v��T���ͨs��=R��C�4�p�q��#�F%L�_�
��w;������X l�aα<�11�X��e<��J).�y�-oEE�`Li"]M뵞J���s��'�zb�������I����x�i�p1�wV�0��(<��@T[D��r�^cU��7��/���IqcZz/�p#�y���Ys2O�������>)v�w�p���H%�R�0���n�������nY�$O�d���#��T5��y�"��t�
���#ݨ=���*f�n�S��D�a�o��iѢ�@i��,�'���k��}�����RO�����|J`���g��E��O�m�ϸj!��| ��h?��ۘ�p"�$��cJZ������G��I�q-'0���Ϗ�̟���=C�{��p�n�\�Bm�@�x��
�9$�w*���c>qJ6�T:�;2B��.Ar ��E����D\�����<��,�t𶜝l�d�c-�{K�1�yn
���ЕVoELtk��Eq�%�y��K��h��&�U�w�z��L��.�H�Jm�᢭'hU���J�����3����a_�4�����aZ�q1^�b���gW�V�xbb�Vhw%\b�5-k���s}:���mM7����"<�^f�9P����E��K��ʭ��E��M`��ZV�E�椝��5Ә���O�:Iwhر6��J*���T�0��,�?�ӥl�>-/;:6��k
`3�,��םZ�`�(�������Yf���wR���b�_HR,����L�l���%)��������6������r��Z�{�&�t��(0��L:f�dehT�Q�ٺETX�Pw5�SꂱZ�_^�����f��~�R�Ss�%�
ӗ����9�A=�*�m�qtֳ���tfw_$˛�x�����w�	���;ɯeo�s�&�9�72������OFٟ������ߛ���U�a%}���I3ψ̬ˊ�Y�H�gQf�dS�->�y�R��Y�ܓ@0�H�/.�'�6���0��="�� �a�Wf�C"��W�f�0�T�8Q|�g �n'�g-p��-`�e�If�X��@�Y�8�|��1��zBm)$0Ga���BIX���-F9~� ں-Nl�uM��yo���2��b6��+&�@3��)��K^{��{Do�F�u{XL�0�&$c ���0c�)F�>
���M��t���*u��q5)d�ٸ9�m���	<�ȭ�p��� �8b�d}��(�P3��&���ŏ.k�g�qŌ�������+��.;��TM���KFVd�r�WM����J����>"BkE���ʺ����듳�g��C�nc�)*b�0o��3f�"^~��6f���ժ�OX4��
�I�E�0r�r�=P����@/�������L�4R�����`AP}�ه�Q����ÿ�������a_�#�X����1�������WB��O౹�����R~���KL�;d��$��`��EJ�����aԏ3U��0*o>��6S��>����#2�k��������\�!�s���̵���������-�vg��X5�V�^�'Š�3��_��(xJ��d�;�7J<d-���p��l2�G���.���Pf@��M9�⹺�XL�l�r)x�W�����s��o�	� 	C�_��ǧ �*�E��DFٟ�JO�99�3��]�z~/�|��7���~/4��wIώ���φ
"g��7g�?����<�ƴ(V8�ƇA�L)"O)�|�a�b~�^[=��;h��>C�F�oS��p�/���h �f;��S�y}�O����-�w����ݷ�g�[�T#֤��I��rv��<]�8Q��|��}V��ב�''S����������=����ׯ?�����K�            x��}W�F��5��r�U�}�P�"B�T�"��~���������2��Oz�{����щ3U�a�m1`e��$z�ؾ#�����~�X�������۩a�ot��&�f#r:[Y3]O�����?4��L�5��A۾���;6�����1�#ʮ������E����O�`��pW�SW��`�t����A���Z�D�����N�=�T �EɜO=���C[:lx����r��R6aPBV=S���2Z��z�t�I������(�3>���s�[����b=���k �t#{q���=M���ƭ����K�P��Ҝ�G"o�@'��4N"[��B�`(Qە�b�i;v�f��9׹.'z�&��2�W�!�hs�R@xo����<��yN'�p������0�#�u`{v�k�\������/�v�_Y9JZ�[v෶�|���9Pg�N�&���{J� ��'v�\0�[�^ܥ5�P��p���H�`��k�o���X>�N���}�BC�Lvt����.Q���)t|�`��5�� A�(v*���	�1�/��G��D|@P"b_>KG�˟u���&v�5d{qk�݄4�Pb:.Fv���߆}l!�D��xa�1��0��^�7���E�(���;@�֓P��ԏ��L<в37�Rn�};ɟî��q	?���x2a$[-2������<-�nlͼ(9���H�N�(����-��/�C!�ڷb�m�K5�Pb�x&Ol�g���~����Q^h듊+�*�P���N�D�Z8P��B7`p��\�0��u�)������'�}陵49nbq�:s��#2;��8=p"G��'q'�4��D�&j�����k{������ߜ��d�dHu1��]�x�>��ĕ�ϝ�2����x<a�07�P�BkU]��mT�j>�}`�=��: Eo�ߟV*�"��R���$ЀA	!��e����Z������<��.��wzR�m��W��*՟NH��dj������kD����x����fDg�J	L��]�r?6AYJ�m��r��]���̚<;϶g#�e:��g����q/��	�#'7����-'^]��;��X��lt{Fw�rή��TlIy�*�W�!P̰���,mF;����PX_N@��n돛���]�?� J<�+��<;!�`}�}Y�e`6�������fJ�����b�������0(!jy��h���0��Dn1�\��On8�� WI����	0�9��}}��;��bq�xJ���<	�UE�G�'%"�If!���I�!�_�î5NK���7M.#��3�0�¤��IM��<EmlוͻM��yz�G)�h�w�y��=Vu��u.��-E��9��(�h^�a�n�NJW���hD�F�m���\��� �(H@3�,�����/i{d�=j�Jm@��% ��E�Y3)S����]���$
�Dg&�8��
YN�l�!x���āj��#b�����"?�q����������?!���2���g,��:�M���"�h����©�,�<���~M@����-�_�Ok�LQ��"X��Z���@�0R<XN�U% ��`Wn�җWhB᪨�mꨳU)s�**��j̼D�0��_����K�v�7fX/�ؒ�]9�]�|1n��?�C	�r�옄.��-���߁��[�Y��n.4�P�$〻�����>�>rk> o�<JߌB	b<2Y����{�p�U� 8�J��'�~�%J���i�ajV��8{$3�:)Y/�A�Xm���4aPB4{?p��?���H~>ާ���v�\<���FV�yY1�Ӯ&��S��->���kU���R��7P��o��F�����2`y������6Ap�j��Ӣ*���ܓ�X�j�׉�	�����ș��g6�*B>pmUy����h7P����Y0Hu���F��ʾ~�h��pm`�[��Iw#����y�p+m}W�0\dt��֑���R�=���k��Ei7�p��x^�W=�h9�sWƫaW�}ρ�c78Y�L�w���Z���0(!�����x��x@X�p�Iݯ��7!�ܛ�L�X����p1AƖ�O�RP��cy��{�:�z����|%-шzn���\e,=@�C/ dǗB�&���Y�AU/u�0�n��&��׼��w.��S5{K�̺��v|z^Ud��wu��E*���^��ڭ� J��~��$�h�#�;�lY��0C�n�ׇ�''0���]Q�}��]�����=nuD.�����y�#�@+k������T�v6� �/{vk��<��􌚯w��*/���h̠ZIP��E�fΈE5�?��e��q�`Q_��5�{}͂3��T[�>k���8��8�}-���&�f�-�;]:�o�%��[�&�*�����_gB�Ȟ��zO�B���H,϶�|����f�}́�Hg��Kہ����!���e�%মe܎��>N8G|��Hx�o	8����h�ǥi�����i����?dC��UEZ�j�'����w�?Q8�i�v����Q���R�F}��8�;o�+R`���c� sU�{|��D�d��ȳ;��*���KnM���y� ���C�,��F�S��oؚ�zm��%��h~��6��%X����1Q���ڏ�9_3k��U����������z�О�+�]2�I��Ǒ��z-G�D�9~����;��c�G���ƪ��z��!D�>���g��F��Z���]���������c`<7���/�V-vZ�L�ʹ���፾֧0� �bc¨`��1t����@��A��eև����p4���3���Y<*�FŎ��2n/�=n%��(ՙ��WE!�ZK�b�U�O ��^��,e�7K#�b
<Ы�{S��퍾e��[�$�.1�Â!e�L[���' Eo,�ͦ��a�cs��`������t�;�6��")��7���E��3n�P��c>� 4��?�T��D��§·���
����~�%�F�<�"�/�=��(�x����IYK��)��1�ũ���Q7��Ŋ��7�旙pv:�V��i�x��A��=�Į?G{i@�ĕOV�����E
RC�Ms�GF�pW6[}gI�U�1��;�����:2
�h��a˲�{7"~�%��Fe�˘�72}�P~�]oF��
Y�8���K�h�\���;\
%h�/��L�&��P�u���~������y�YL���%��f>��K��#M�f�gZ���֠�Y՚�cG�UR%-I�h��f(s\v#�S����߄���O�"�豯�ƊFH;�Y-�� ���N�t�V;�t�=�z�|�K�`e,�����H	�{��iH�u��v�y�62�����Pފ����G����F�<��1���H�V���1��:'e��"�e���/8k�9���f����A���Dsл_�(�ܖ������xu��󡂾e@��#%+�C�^Jw;���l�����=.��Z�-b��&$j���j�`��ՓPԫ�|\l�)͆_;!�j=7,�%��^�Gd,J1Q�5B��)���,�' 7����	O��Ծ�P`Z1�PV?V���٫>�Ev(��-6�m,�6H��Vn��D���aS� ��a���$]潟6�Pb�� [�oDv���C�8n󞂛<��D�lL+���)��k0��:��<8���Q9�?�~��OJ7<&ݮ0Ou�ک=�������T��3��f�^Io�,�;��������۳��=|:�r^���3�=J q�&��R_+1-.�W�w����F�|�sT��1��U
�S�'
9����W�˹�<WV�G�}�P�6��'3Ic�i�j� *޾D9ﺦ�E=> �v��m��u������Lc���+���ݢbu�T3�Q(Ab�0i��s4<�8B�Jd�1�ŗý�ʹW�_f�9|!��,`D���0;�@��3�\��HH�#� �Z�'�'(n�����#�(es�P0K���7ʧ�    ?YQ�?�g���b�%�Aٳ��V����秆�&iT����B�6l����P�B|�f�dxD�G��A����~0�{�/���čU��8�I[���'�F.,*��`��tk���H�-��մ:��¹V[|��W�0Lv8?i7ȟU3
%H��LZ,�V��Ã��������J���K�G���=�.���b�4�p�S�s`9��O�<���D���3�Ѓ�ˈnћU'�U���3�'�䅭�jEu�|��������ow��`^��e�J�Ъ�XAz}���\�3��~��t�Dh[ѯn��	��/mʛ�g�co��ڕ��_;_�����~e'�)�P�M7N;��V����Z
N��`�mv#�х�P�	���o]�=	E=6��&%�="�z�p=��<*���MD�đ�E��.�=
Tbi�����'��p����:XE
n�ɚ�ibߗ�p�q�(E��<].�@@�ʶ��a�	��Y(�I}#Q�D�W��j����x�%��o�
ac81k�UȬ,V\�:�OP������i�<ܖ��Ld7|��ZK���mIB��'�"��4��ȯU�����A�W����L��!�K5��D�fD3+�c��X
�ؗ�K"��_�p(a��É�-���b�-��(4aPBX��xԠ������ĕ��Ɛkh��Q�ΰ��˩Coׁ>�����B*JB�:���S����V|2�]P#\д���{�,�,ҝ��?*��&HsH�Acto"��ժ90HU����Yp���p�Td�Y�h-�����{�}���y"=]ӆ=��n�Y#��f���bՒp]�g8�|�܂Mu�����ٲ�ċ=F���J�e��U��U����ǧ�&Δ��	m�J�1� ��౰�� �?d����	ե;RP�\o��Xw>/n�U�i�&���a0�f��xD�VӼ�2����I]1�&&{ ����1�/0�()�����u�+��;y^N�o8������a��@���%@�VW_`(Q�E;ڟ_b��i� N_;?g�����3 ��n�(-	�as���]��?V�o���)G/�|neg��LF3��7Yu �~������s�T�ѣ��On�����+w�t�+s��=ٕ�Z������e��d��c L��ek���=�5�L�X�Ot�{�.ze��I�[�D9�l-u�����*H�s0�H������A���k7�p���e��Qx�x�ay���@��v�2u�+s{�;�I���h�v��=Õz�H�֪�-F6J��*G�j�*egt��g*�y���ID��\��ق���#�Տ��twv�ߎ m�%�[����_̑�q�.���<í�_p(a��I��x�����"S/����W���p���)P��jx��#M�id�����?���KK#X+��92�]@��q�r����Ms����C�8�5��VlvU%�]L��1�䥐$��'6v�*�����x�� pQ67UX�}��!q�������OJ@(�c°��֠�\����z�7J���w&肢D��Lc�H>/V�%��]"^���:��m�� WU�zk_��/�P�Q�1�ܟ�1��\��.K�m�5�"��l(����P�`k�l�S�L����
�/0���nx�� '�c��~� p#%fJ�E�s[h����� p%"�����x�ΖcL�w>�<�.�h���$S�݁����\%��B�{
��۝��/v�|؏d�֖�<����D�f��x/m'��y�d�ϓ̘M1�u�s^O�d8N�Y�$5�����ʇ	�����w���"O�Q�K~n�T��Y|��c��	�0��y ���C���٣0����J��\�oǩ;��O�5�N].Y����
�j��������4�2'M9�w��"�g��8�Ӝ�I��N��
;��Ϛ�� ����S/A�s��@�ծ���_d��!������y��7��y��͚a8�䜅����#瞎��^�������S${pLfݳ�	A�U� T�./T����-J�9{�4[�vrLG���m�ryܫ'Ռ��W�9tLz�ʊ��ȥԗ[կޓP���Wr�>o�\�u���n\ρ���ɷ��Շ��C��׍��V��g���Ě�9��U���3�g-�� A��g��ޙ�A&e�,dǊ=P�z������(ۛiV�asI�*�3���� ��@��{�S?k�~��oj�T^#%F�O�@�2���4]�n������Rq߳�"gxF���(��|��¾l�}y����IZ��N�3�Z�)��9�_?}כֿ \��jw>���p��ٍ�-@� A��g��8���S���%em�f3
%�M��=��,)���>���z]�����4J���)W��{%�}���3�2K2:Ԁ�w3ozV��,G����z�Z&�}�ܯ�����"0��ۄjI8�U'���f�����E�>�[�dPj~�sE��i��ǀ���k�%o��f@�[%ؒ>�f[��a�
�kD�����{/C}�I5�Rr�*���?(j{T��8vͭ��;+�f��:�����c�g�=#��8���^Vj�'b��pF��(u{��6�����R�5�e�!���E��[yDE%C�z���S�2�����������F���Oi}Y .��כ�����bҋ�á{Щm #0�זWA(1ΰ�
���ф�-6�)���M�� �/�એ0{)��fz���Q�&�g�5�pj�lk=�Ԗ�c*�`�ՠu����F�[�%:����w�_��>�K
7�Qi8D.[ݾ-o���E�3�R�|'Y���8Vug��夶�׌�E��%�Θޢ��N
��D�%{oi��H���[�b���o�E4@P"��P�����Lg�ڳx�RԄ��w�ݚ�H��4a��s�����t�^�j�{��0������	���y:^��~_,u�#���M��[4�Pb�o��ڦ�� ӟr�(��	�#G�^г�l����?,��T�*.�"�����y���W�>(�E�/��!�[]�Y/���Ј�YU�͖�x������`���x�?�ڟ��kơ����|`l�i��A
L8��A�zbx�ՓP��y�ɒ]�9�q����^ϡݾuROC�G�^�������w� �ޮí��*%su�(L?0#�p!��*\3
g]qY�f�����{a��j$�>����s���IEWt�C�@Ӂ�FV{h'�x�N�NX�7����lv��x������������˨kD�\bW���a��q��+ʪ�PE�ߦ�yM�r�f��j���A�i�a%6�P�Lz�+g�D.N����义���"f��V��.��6�����퀻j���D��)������B�F�T>�Z����`�JǓ��5V����n娪��п�p���m�NJ��J��N�c�6�>C��:�iq%5�Ʋ�FQմK��V�� rV������������Ԩ������bY	H�jWu5;�Rp��fpG�/�Q9H�w�[4ap��z;k��<?<*�G?�=f���_`8�A�f4.M���d9���}^1(!YD�$Ol��O� <{iu�rl�Q�X�E���O"��r�N$�t����X��2��u�:�4��;^� k~=��f�5�P����8c�h�_j��zR>:E�[�Xe���a~�۽�D�������|˃�v���Ԭ�������e���bM(���\���r��:�t�4u�v����> �0�dik#�4�;w�^�����Z
N'����+	\��p��SUC���_��i;�T�s&�ǌ��5�Y�!�o�m�/�q6�mm���0x� �yz�{\\l��k�\���F�ܮ����|Ǹ�N!��a5T�7o���3��JI���y���. ��+��C��S,�7 �N��R��e@��߫�8��Km��'PE�I9(�IB�t�2Y}km�F>F�ژ�Cj�.�p�Op�':�J�]0#O��"K9�kl��F����|�k�r�R)d��/���_��/3�ĎJi�Y�]e���%���8���F�61ρ��XfN    �h)t��n酶\ۓq�~����r��!���c{u���G�%��TM�%�nE'�e��^��Oρh�A��`l �H��Rk�$\���?v���,,��U� t��#G�?��W+����.k2B��U���ĎԴM����v����x_`���j7���5��=;��ڬ	�kGϠӽW.�(�ȀPv��A�&JH���*����q�Bד����%�ܱ��m�{݊ж�� &_���gHׅ<����ѱN<@�Dv��(5x?��5n��[����ʎ���e���/���v�w�Uć��A������n�O�>G�C�G'��"����Ǚ�F�z��bgn�6WNz���*�^��WJ���):�5����!���88z�F��:�ag;�a�I���u0�^�����p�Cq�
�O���c m�vF�5���\��H�t����I���:h83����l��f����6A�H���ߢ
�{O@�k#p��BOf=o�TLIR�u�k���tslE�7�}�L��_�O�������\�H��L���g�y���w��� �(�)�n�D��u�^�������1���Jt'z�M����0��k0�m9�{\ܧ�,�Dy����v��y����_f�u�Ѓc��譨�⊹�eyS��$�nP�Z�������J��ֆ/0��1�	˞&2�yV��m"���A��{[P�:��ig�c��؈B	j�l�})ģ��T�O#E��H{O����|P�4���0�WT�Ͳ{{�"�������;c�F�v����k4�p�ꀖ�=:���=J]�+��uu�r��&�.X�M�Xl��hً"�ַK�g ���R3:�AZg.A6�� ��Í3(c�t\M���ڀӪ�9׽�/s�7J����b�2��g��Jz�\��.�5�6k���,s�����D�V}��p��}��e�t��k�u�j�i-	E��O��%���:�Ȫ�I���\%$h���:[A�t�Z��s]�'7���dj��;�|��.�{̢��"������bK3r
Ȳ�-�� E�a����^���e��Թ��ק�2n��X�'��G�}c��I�s(F+��I���	FUl�媃;�K
�X�.UPv�M0��y@[�r���j�Z�|�R���٤N􁭺������w��%�$Sg-�]qӍ�#8K�q�[n$Т�IGՊz�ᴋA����lVOÍ,�:�N���_�2�O��=�PG�݋r���n�"B˥�����'Z1Y�Ћ�������-�OJ�J��ұٓ�}O t�m�� gz=s�6���f�Ϗs|� �l�vQs+`.g������敃�8j~=i��<(��(��J�8��w��ZVd�u��M���"��Ϗ�EĖ�T!������	�b�1#�֪�X�~�F�L/�דp�[b̼���a��	pyr͗j��T�K�s/U�h�&��/s�sp�(�C�c�	�w�B�[T[��D�0q��h[-�h�8��� lD��&x�qvO櫾T݉�z�'g
K��&�s��Е�W��� �3l��l�r>
��u����e`��l8��zЦdj:P���f.&`���	����f�J��Wi���,A����`���r����?��=J���I8n�>:r�������h� },h�X����i
�_��f��� <9�~����	\`lzr�y��(��d�����'�lY5�xW����F�S���M�z5�π��̧c�t<gD\Y��}�0?*�[���.\��>>�2[��n]�a]�e�>�ZӇ��ݯ�L�L�ҵ�k+Q,�����õ��p�P��Ks}�L�6�1���l/u��-e_P�)|1���Q�z�U����sm�7�P�B�aGk��8+�|ݿPZ�O�}g��9v:�VND�~� k��'�~6���[�8��\f7!9�Lp+-y��7 p6��M����n�U�=��=�n���(�
�-�]�y7WUe�箥��v?z��Jb��Ls��:�n����{K|@pAY9]�����0�r�^����(�|��*���O�MR㤔�ݰcc�1�����_=��6n����v��`(:Q�Y�\k�༂���[zDy%�����_�~ pv��#�b���)��ֿgՄ���P���0vi�A�c��c#����� �h1�LZ�W;@��3�M{O@�
k��.z���̹0� om-��+`�w�E��N�)���nɻ`�
��|y����f>>]Q�f�#�h����ykM �	��l��Q{F���&��?]���`�s�F�q��f�6H<ݢ��6�k����"Ŏ;�+S)mk�^��:�Տ�؟�`(Q�Μ�+�cOfCǮ8#�m�(�WypB3��z����Zb�y��-g&�S��ՙ1:���0��M�C�|���e�	IP}���{E͐u���!�	�s%��bIwG�=�bC�3ު�5E�ד޼;��ҝQ"��#�YJ�U?83]_���&��.�z��v�� 7���v�y�p&��������!ߓ,��;�b;>��<�}�Z����{�zk�O�"n����$��\�änD���g�+Yw���+�mZIms�7ΈS��=)���6����0�vwY�0\J��G��NRm+}r�_d�����������>�U�M��W&V������Pb��p�-&"'�b���.Y�%�b��fL��aӭ� SuY�5.��E�_��U���C��(w���=
�\m��-�PI�Z�����d{��`���ZK�U�l���X��x��Q�]-��j�'�hW1V��"����R�
,��W��m�����%��P�{]E�U����������kƗG��U���R2��$�G*"ʞl�nG�Y��ȂI�Ɂ��mj2f���j~��)�bg�l�X����f��G�r�ǝt�~t�������cv�)8f΢(��,��(�r��~:���,� ���i*i%h@ݓ9!OÕ����a$p�>�T��fq7�pʀ���9t�E�bkx���ͷ���
�Ϗ���ɁM	��w@^� (-s�q�Ҭ!�Q�#:x��FJc&�Gq��X�]\8�W[�^	��h�ͪFT.��@مTL�OM�5Jܑ�cT��ՠ�mb�º������Z����xe�>��j�z��6�O�U��$fGɌ��{�Е�s����浒�ߛ�^�o*2���z�?�u܍�I����N�]:n�K_A(1�Q�3��e�ٷ��1	r���_Sp�C�gL���qw%��R��:g��p�,��+�PM����Q�捈9cM���14��-�5�B��JҤ��6*o��-n�c>��rE/s�#-��}3z��� ex���"#-�8�C��(:M��T:����y<��v����� ܔ*n3��9w�m�D��[4n2>�0C�&��`�m��;�8�/�M�B��P@�p���ڽv6 }*H��r> 8onLXf4�F�j� ���"8���V�~�7[l�8��ӱ��oU���ֽ�@(1�Yq:�B'h#U���}��4���)���n`"��vo�J� PrO�*E�J1�O�:�C}5�P��4QN������L�Ȯ�c�[��5JdW�;��ބ�44�%L[��j��\y�t������ed��J�Թ�r󖀢e�-��g�3i� (f��`k��Wyp�rJ���p��fn�݊��z�x]xO��1/�^t,6�,����������FJ�+�	nz�?-�c��h%�>@�R��D���	M;t��������U�����I4O�egl�7��HIR�D����7n:c�r4����)IH�Nz��FJ��ۘ��VL�:	��]/��f�p�P�,�����qPڀ4_�U��cd�y�r�x'8����p1 _�(]�L\j�J�@B�Ճ�
Ͻ'�L��<p�1�Ca�)���&LJϝL�p�N�Gʎ�dfX��l��Z��\��D�Lm;�*7폙t�t�����3\���Lv�m��Q��x�A��g���q1�s��2`�o��(��睚Q��>ċ�q>� �  �e� �Lo	�Zڕ�)�n'���u&�]u�,8d=I�����6[���G(ʱx,w��aĽ��!���l� A�H�ZϞ���d~��]m߯h�C�
�3=S���	d�;A�����a=����_u���i#��j�����]�F����k�^�kF��}X9���8G���f�>�M�y>@�������^И�F?������\(�>n�&�
#*Y�9���w����eGo��$*��ӽ\h��QR"�<x:�V��w��w�����v�o��76� ��X����(�� f���3I^�A�%>�����gK�ұ '�܈����B�{�;��<\��3D����eD��z�����ƺ��h���;�$�3r�׺��G�� 8v��W��Ӳ�HKfr��� �����<z�	�d�,�kf�"��t­[�l@��V�۩�1eyK1�6����F:�k��bqq�Zc\���%N�բ��T �0�DP���l��V��j�Kn2��5�S^@�M8����X���9�7�q�O�"���y�źU��g�֋���6�������8�*Q�K�GkO��%��i1E[��I�㿅U�Ɖ��Qɭ��' /�1�`���_�v�F�_*p�w����ëJ|T�o���&dgz�H�@����iK�v�tA�~o��ܤ��終�"�!�[u����hw��Z���/?���	(Ò����/P{����~��X��~۞��3J��n��P��2����рԋ6��7ME �߆=��
3s�T��z)	�ڃ�@U	,ŉk��'u�vt�&���A�g4����N��m0z��:����яv�3��E���m��k�xA����K��@�&�R���(�!�ME�O��֚�֚Y�|՚Ē���G� �R��>t~�m�7����ư�`��m��KUoU�2�f�u ��{gt��2d� *�J=50V�/����0���
�~hN���~���o�|u�         �  x���ْ�J�����r��	VA�QT@0ND"��,nO?	�]��.ɥ��?����t�98��I�;~к�ahG-/��$��n��$�x�l�����sw0��w�NZ(��m�j#�"=�aD���c�1�.(���W#QzR�$��,yF���V�(��q�-v�b��[z�����w�NP��k>�|�=�pN76ZqچG�������vRψ )�k-�o��z8�Ý�h�҂vDqk>y��D�y�Fk	)A�Zf�/C�{h7���x [���@xRm�*�;mb}�5c��������SqsvҮLY��k^�⏟M����/@��vr�A:��rY�Vw�[=�����`K�/s�=��z�1�U0s:��`O�$Ip|M'�yG�{�_'�(�{WV��o�
>�{�w�G��&j�-�s��@���B5���v�.!��W+�AE0<�u���n� ��#�Q�*�R�Ǳ�;������q[��P�L��kxG��y�%V�Ѐ�Tǈ����.F�{��V��=�X��a{�����ھ�})���?ado���7v�}��*+$���9�Ǒ>!�&J����(����s�Q�᝼�k����N�׾��}l����֪FA�K8����cO�}�x����/�Y�{���D`!z�ñ������Ώ�v}VAL��@��	�b;7L��(f��Cƻ�>*3
++򏥥:+��F�5�:�>��#��l�sq07�m�G�$I��0f&[�W���=��x�J�osw����:X�-�`'���iD�6=F�P��ZՙD�_>�kDv���*��������:����K���d|�Ƴ;+��B��X��IU��=�KfFj��ɦ�}�AQKl�v��B��	�N/xЯ�*;0ܖ�Q'ޡш6̭F�L��[T��*7c�2ch[���W�X��mD�A������-e��G����қ�����u-;u|}��4"+ZD������Qd�a�6�I�l3,���d��|J�b}�صT`���ZQ�KDmQ#���bdt��;hh�#��&��5[�M�a�6�Z�3��l[���-x�^(�MR�B�:&m{^�nfV�,�S�>�r iz��j���ţ[Ѳ-��bs�9��jѵ
���ǳ	�V4-����(A��P�X�i �?|�3��gW9�3�K�ݕ%�޽h�<F��-#4��(�Y.{1�ʫ=1���s�'�O��Y��˃�02n����*k�P޽k�ɜ��ꓨc�%.�G�Pb�I�tԊE����<��A��g��+�-�q�����h�V�g{���t�J�f�w�(�,�������Yp/�Y�i�v}��;׿Aq1зF��ʶw�s���H%��f�.�����Oj��$��lN�-{��8*��Vd�32��jQU��bt��#�O��]����1e�����;#w��h���:�؅y�[�Q@Eጛ����Q�{XoN�#I 3OUᕽ~v�n���Ĉ����b�k�b��Y��>s�SC��Vd��Q=n��5&ѳ�\��񤾏~p�-��C`�]k�4������<~�Uʃn8�-g朹��K�!�q�9(wS;Pk��L��"$O��֏��6{�݇�0�:y
 �
�IV�*��2Q�,�NI~��l��M�;H��:,I4��'�e��N�Ď��d�֭e>���w�'�0�&�`D���8���=ro��x�r���s_���=� �<�{M����ڸ����)�
w�z�&����Y�ֲ����rH��~�$x#�]�;tB̨.���ġ6�	��1[5�(Zݨ(�-"9����]��0�<4H����s��p/o�F����>Ǯ��Z�-A��w3ςDP���j#���`ː���f�+3���B��z��w�_�	��v�́#���V����\kDW����#��7���I�y�g��9o�Fo�x1���dm[���|�5����$�[�5��꾁b���Fx�G��n$�n>%��;��3��O�^�iU�Z�]q?ro�wA)��Ƣ��L������L�.��1=k���o���l�V��<#�ٙ؂=�¡W��Ft�r�����(��{i≃�Yo(��[A&(�ݳl�W�`��IEJ&��Lr,SwО�}h�,�P�þ��Ԟ����qЧ��ӄ�*[�;����x���]E�n���U6�+��)�:�G�ޖɾ��R��QOFj��RC#�1s%�����<��@&��4J��m�q��G,�t+�	Ό9����>
���)k�f�7�M1痏s�ԤCK�]����vM������{�C���ٝ�͆�T:Mݽ+hh_�U4B+ڲ=_X�
���)�Uh���?����h�z���0&A������A�*{���wC�J����[�D��/��M��_���RJ�SO����(���VV�i�-�=�/�N X�ь�b��(��%��)P�*D����/C��� �l��(��(kd��cu角v=ׅC�G�Zl皮Fa�9�LR����J��˟R^��(��RFW�fE�	�K��Z�T��Bۗ�:Y
g����vˈҎܥam6�1�]���I(r���|�!ŭ�p�ﱣLH�*��k]�����^7�]��7<�J�,$zr�!�Y�K�%��Y{���4]���$H�sl,�Sx����U_I�� ö��u�v��}bg7MY���]���ǈ���[%�e?�&$�����j|�V�/�~�Q���S�q�3��keFNX~so1��3ܑ�(���|+m�_I�f�Q���y�s���g�u� �ș|o���pH��@}b�=�/h��ŋ�\W5�"]ٹ��҉�U YY�}�]%L�u}:�GzP�b��mrE�!v;�Q(���rŎ��
!�@o�=_�wrb$qW(;��3�_zia1���\��}��u��xR�O�x�_�`?;`x���vc���V�a{q� ,J�	�s�	?��O1/���]ȳzI�38k��|	B�AD�c�~������u���k>ne
90�e9��f��S7��`z{�9����FEBզ������`�L�q�N�=����?�j�&�w�9O��$?�z������;4������/���>��A��� �u��w��o������Ȏ��P�w!��#��5�o��9���hv.<$=�&�a7r���v���~�4�À��ġ[����j~[t�A�d1A�C�|m"���,�}������0��`��gK�/w����zha�o�h�c�zK���-_ ��>cAڙ��
-u9t�ΐ�Q���� #��c�<���wؔ�OǏ���u��=dRiv��˃�-�K���^<���D�Η�u�N�N�X'y�9䍀����� 62�8�h~�~���=����q�����w8aIU����i�x~���ʗIY �H&	7;Ò���9� �#��W3̵��iF��;��#eK|_��'}f~��_~�vW
���;������1�b-Y�F޲�F�ҙ���2����d�\��
Ë= ��~W������c�#�}�X�_�/h���)>�)�ht-��҉.B��
��
�A3m8[ �/6u��>Yxs9�����QR�~���g��x�5���e����ߵ�;�f�#���
|� 
�a��Ua4ۄq�$�:�x~_�]���b�c -�f�]�h�V4�;���8��C󆠿#Fuӽ�5�0�k1�%;؆	���,��W��Ip�4�,�,���J��<�V+�l�@�l4k��~�<�8��w����poݛq��w'4Z�z+|e>l�?�����?wT�      	      x������ � �           x����n�@����������rSQ�T�U�E��j���!ioz�d~�7����q7O���؇(V�`}J���5 [H?Sv��>�ϯ�Y���ɩ�qY�l�r��fuV�ס<�9���?V8��3U#,�l@X�Y�u�͋fo�tr��@�ܜ�!��d<׎岖�{}�U�e���d]#vYIe{ ��Ӂj��Q�l���'4�B���~�2��C��IqU0�u^�P����T[��4�p6Z�H�QE�TX��-]�]��-J{�dY��t         �  x���َ�@���)|����~�"��6���ے[Y�~ĉ��L_TR�����Oђz���YQuY=<hs��Zh�4�	:�R����ˆ�B�z= �~��/PyAb)*&*����j�4O,�Bߊ��Od��;��,����&�*<�I=�q�8}�=��e�iE�iV�y*�!9��������v[d>݅h��Y��P�(qԷ7[�է
�H�Gf�A(_��H�2�{�X��q�?�x�м�{�c����XH�"�u�^$ĝQ����l�e�����~m�Z���$��2��;aV<������En��M>�_Q��6�����k�
Y� ��S$i�gR���5s��(�ab�Xuq���4�BA%�F��NR9�6�{�^�
.*_�*������W��~�ռ�         <  x�m�Mo�@���+�^5����Im�F�ڤ%�2v+�~}�M��6�f�Ó	#g����ٙ��-���L0:ꪁeLF��T� �`wT��pWbV"]�L��(�g�G�1=2.t����
UwRR�H.L�vI�U^���S��l�\�3ϔ���Gv9�U�_���5��l��vw6�WiO���L�گ�긮c�q�Y���o�[�	���a���}b��?����4�g�H��]�A�b� @�t�MM��c����dg�s�0\���P���|�^֣�� �_H�����_��E-˳��f`���      7   H  x���Mo�@����+�x�,ˮ��J��l��*���P���b��4i�N�4�ɓw�yx`��L�uD>�2�����F��Nh㥎,��pl�Cf��P�70�[��Q����>��{�yz6�"���;&2b���)L�D���Fu�AP����7��a������X޻uGT�M�M�.��
��� ���Bl���(�C�oZ�Q�u�˳<	E)��[����<%��ë�#�,ʶ0 ��klz�*i� E�8��XS[��+�Ltb�ؚƖ��w�襜�^\W�k8rK-N�S8��Se/����G�m�[�m�?�����V}I�> �-��            x������ � �         �  x����n�P@��+L�3�ް���#�H+�B�QDQED���\L+��>�&$@���53�����=]C�ޓ�.�A&1$&�0m"�'G�ۘ�*'-�[�.�l�}��~$��V^@q!��$� � Xp���Ǘ�!	&�4��+G�ͦ-qgY��K�I4��j4vp�IdVY����v�RrX�|�HHxKOA��ʇ��b}8�Xr�	�)�@�2�����lqE{=�4m��Ϳ��(�4|V�� �(�i�T�ߧ=?�wi�)):+�Z���l�`x�{R�n5E���aR��ӧpP��S�����=};� z6X�'�,��x�q�O��nS��pޤQ����3�b�*J�}�A3��H70Ӌ��э�>7W�mM^������4�@Q9$o��K��Z%g�$V"�qĠ���}
X�b��{��g��z�fQ��Q��@�"�Vk���:gm�[�.����>�r�ܭ- ��^&B�M�A�B���Ce*"�E:���^`ݪ����w�gvN�;V`�O\����[��,;Yw���E#��F;���t��!.�<��d~�rB�4���#���d[yo�J�'�P]��.�y���C��X�ǭc�K����p+�_�])�=dی,QN���8�n)�0V��0|���/@�+�WQ�s«�A��|;�ULp�[�A��-��6�-+@*��Kvm����F1��&�y��Ҧ6uI
h)R{� �Yv�	��=G\SVo��<�����? ѐ�         �  x���[s�0 ���+��I�p{�\E�/�"�
T�ۯ_��ۇ��ݲ��K2�999��v�ӣa;�`�G�^�5"�ϰ	 ���8|��z|�L/m�E��a� �!���'Dq��4n��&\0������(����r�%��p��z�)@���e7Hq���W���aH)�<�I���,d�9N߷���:A�4S��� ���,Q̱Xj+3mb�'U��5�/Dܷ��(@�mjo����f��?�nP���^��{�L�LP)	"�9��@�d�^|?YĎ�� �Y�F{�C!=v	=~f�����.�Ua$$[���k'���3����J��H�f%U[�8��l�	a�9�>l1�ae^�.��v��p!��22ZW�6�cʿ�O�=[w����)L9��|�	�r$1����Yz��V�v!h�(�u�G�n��h���k����!~����"Y?Y�jo���Y*vN 	�ܠ]�h�i��W�B�}���_U�듮�4ZZ��r�ک2ʥ�R�^��0�ĭW�N*�JL��j����n�%���Nr@^�%���G;6�|��4����ub���1	�F�n�Ó5Uw�5���2'MPiIv�VY���ao�Ty+	�c� �&�4PTOL{�����;A~}��f? ���R      8   �   x����
�@�׿O�(3:���(p�II)n4+Ӣ�BO_DB�
:�g��i���9ge^��r�Ʌ�v�sE`��g�]�F��;���Qn�#������0�rJ�6������A�j���U�f��Ǝ���8a��p�w�:K܅���fjX���ؖ�&{��`��g\'�0�7��~(���(l�Q         �  x����n�H���S�f���`�3'��c0���l�1�lx��d�;�E��"P_��>Uu�5���!�I��W�N�WG��A/�|�E�a ��0 �÷��%dL'{H���� CL��7�<#����a���O���0}3�VWA#7{qC?�wU�����H*���O6*��{��pf�b�lo���i	m'�Mhs4�ѱg��\�hM_rZϒ;��"RqA���x?�ax��ɨa��xW��b9>��W�ł���1�)C�Ĕ����Y�-XF?����$�/wsU�]R��a/�Z��jX7lǋA9��,- ��g	v��jۋ��o�}F4����w��;��8b�<�'Ŋ,u��kM`��g�yL���>���y_�x�_�U��3	2;��Rf�-�$��?��g��	�S�������ݡ���R�l��h��!�,]�VyL��o�N���}��;e��;ϟ,�y���U���V���.��Jc��h�`�?�M�6��Vy�~�7C�ס��c�:ٕ��bmtT�)����j��뽡��1�IOk�T��5�A{��aH'����V��^B�=QrK_ Jf�I������I��Z��t��n2h�B�Y�a��G�ӝ�ɯ�q�@cW���f��6e5��LU�u"�5�ʾ0ʓy���j6�^�/7�*�';`&�������ZAQ0         X  x���ko�@�?����f��|� (�ؒ&Dn�w�B�B�KKH&��yx�{��j�X<ק�;{N�fl&��хvg�g��0� *���c�-��:���J{r��'� "M(4��ǋ���W ����R��!b�;.�s���ֻc��8���*g����:/��5?��8����_�c"���wCc{\G67 g��㖏]�Z.{�p�F�W��y"�qsm6s�g��琴^�Þ[=���W�@(��R�Nv��O�$��7@\�=p{Fp�qGR��o��kܔ&"E��a����̖)��w���� ����fF�N����C�L�[N�����:�fVYa&BV�˳""���r2�������n��ޭA�*����U��� �p��@z?�f�p���0� �3-&�7���or�JGA�	��:UϋCpqh./�-OT#����p����s�[�`>k9�sd���e+���M�.�#.��~tܜ�}3D��`1��:e�^� �%m��:N}b%(OWAlk���h8����S3ύ��c��B����K�DJ.ri\w�&�w�dW!u�z�T���c�������         %  x����r�X���S�2�>p�CD9��7�� ���$bz���n,�v���g�-�M�69[��,�ڞ`I�/��b�$�o$��W y��!M��.��<Y�{��dQ/���~�&�:�E3={�`. �5�ɾē$O25t�c�G�w�F��%����W�]f�%����^8=؄���l���=v��4�/�:��*��a>Q��=$M@�����QO�p��H�=���H�7#��t���6��D����ϖ7���R���[�Z�{����~Ř����u/�*���t�e�Y{q��۬r򽽜�3ƞk�����}[}��_��� �<��EY��Z�O3�x�X)̔�+�Ӝ�{?e�]�K��2w�R�:�)�Z}ǝ�ީ�dl�p^����w Ә�5��2O��g���1\��{��Á�%F:��c��3Iu���n�;���@�1��c\���e��S�0����%��W�_аӲ=d�n���HPv0���0��8��<�����*�	<<Ń�ڋ�^_�ܵꮜW>��QG]Ӂ+�ã���w�L��b���;Ճ^�P��s�6��u��O;�oMyH�b�"����'q�E*:��ٞْ�OF�Ӝs9�jd�]u%q)�W���R����EUF.�V$��u��q�|��y��F��:�(�L�z��ŤlXS��2Ԕ�1�y��,�6�݇"A5����	���J�qJ��"l�
Q��I�� '�nB�+$Ʒ���:�6׼$1���+H���PęI�&!)x��/�}<9�i�6���Шd�����*����-�o���4Z}��Jw�gU�T6\D�&����VpC��ãq�3��a@~/�#��C�U��Fb�O%YN�QDIn�u�F|�ǻ��y�!��)�<��FE�V�Sel���\*�L�I���>��f�Y�pg0/��!���x �=�	w��@P?n�~��=�V��lu��}!�[Ż��/��6�cw��*�1t��i��	�뻲��]&)UN͇j:�S�2F��:.�QɅ'��f2l�6��(n���m�I�N9�}�Ѡ��=sRQbOz^[_fhߒd>3�/�O�� �o�7'\�UmW�]���x��qZ�X1�-n���fE��+�
Fi�
� Д��7AI,�;�C�F���2[�{�����5$ ��/ni�=&�<��U�sa�3�%���~�o�*y�J�5B�%W����oYP(7]�zg��]yyP��Ԓf���-�R��=um�Yx!0�U�M �c2R�f���;l[ˠ�Z��Y��㯗���,b��         '  x����r�0���S��$!�ށ������8�X)J�>��=�:=�=a���^y5�IHK�[��OA��,�7૖���gX�=ƾ`��C�u`�����PG�
���$�
� �U�'�t�gs��Ôe�E�и����'BmBy�7�GU�.Y�$0�N��G�cZ� �YH��G��W��Q��{��q噻���
�$��>�a:[Sʲ���g��K�����t��	'�}�
	��̰�a=3�+U�]�d��K�@�A�p���ɡN����clq�n�j�\���Ÿ���B���/@���)T�<��ֱj�'+���c
T�6;���˅�}zG�"�;l�h�8�P- ��ׅ�MKtn��lb5�NnvL'6Ð�CsU�y��������V�c�2L�D��HӰ�0�w.���N��̂lo��H���F	�$O�[�n���1T0�����K���5���ʌ�=��G�e�НN/�~?�v��c-���MД�"���_Eoֻ櫈�XV��S|�gq�[����a��~��;�^�oϵZ�/��&         =  x����n�@���pހff�a�"�!��h��A��R���WC�6qa�Y�<��Vd�:�S����r>��G�pb�^� ��0oY$Y����y�b2��I$�����@�.�־���1M�=�x�X��SD�o�e7ʹ���Rj�9+ۻ��O�M��D�D�`�b}�+��L�����#kJC��մqߍjlo�e(Om�ܱ�T�E3�2c���<@D%T��?[��f��Y@�a�f?��J/�� M�9����5�cI���L�ֽ�)�/�*��(?��~�y#�VNOq�y�$�ʋ� !�J����	��+�O         a  x��U�r�@}n��H�7��(F1�Q+U)uP��ѯ��p	(3ѩ��n�>}��sw��t���'��� K�Dr�mk3ܶU}�����8���j<���$sw�D �F@��L�4��:�=���1�|y�F�b��Հ����a�3~*j�a:ێ ��>@�K%�0(3H�i@�?��i�J��j�ĩ��N#
b;�(��0��!���P��q�����l����.�"������Q�d�����;K[�E���H.q:3�Ir
�0Q��(dgjpL�(W���,��6v���H��a�6Q5�?�]cw�ﷀ��8l LEںլwF<u�~��W�t�i6��*W�!���/9����jrk�;5!��0������b\NYQ9��o�� ����6Twg�|����"���w�H2,/Qk3}�c�)/4��H���Ȑĝ+��\��$�F�˒��s���;1/�\��������'ut�]1Z=p�'n6:G�[˜�WS�Ѽ�\r}{θ�u���pgN�5� �������xb\P9,̝�?�P�Tp��O�o	�+��4��@�[�W�%H�=�\P���4C�3���R���A�����         �  x���ˎ�@���S�ݩ�P�DPn�6 �Mk#7��K�<��bF�̜�I%*���$V�b9����"��J�̥˻!�}UF~�|�����W8�w��{���31��n;�?o'�2�V�$5��k�B���1{�_���B�XOa�0��2�8�0~�Ǣ�F��������6*�����R�?�M����
c��W���Щ?[Y|n2[
����@��.�������  �Ԕ�"Ĉ� �����9-���ir�%{�ĥfh�;Qd��닭7����� �)K����h���:�+�M�]�+|cOv�"�^��� ��5xqSF��Ld�2�?�CG��z{a���$m�⏗V'�,�$P)8v��h��C����o 8|*7&�x!����7�]u্�z\�ٴ\`�Y�����R����B,��>^'��o����      >      x������ � �      ?      x������ � �      @      x������ � �      A      x������ � �         �   x����N�0��O�� NO�n�PG�!�7.^��Oo7�B���i/��|���]V|��5S� �c�հ�<*s�.˴(j �`�j��W:T����Ԁ����F�}R�/���fR�&����I��!��z�#/�Rc ໕�.���$�y�RY���8e�78�l�Xe��ӷ��fV�����Qh�/��&�2���"je;����/NS��&�>&�V��#h�Q��H�,�qO#���;f�         &  x����S�0����W�oCco%��V�q�Y��i����w���Ҟv���~�o?�ً����M�y#�
�:&B����T�y02�Qiٷ�8q��A����qb���
f@+(&.���1�"���s���&�ݽ�<]U���Q�.�y� �w8tj�6��L��?��u&6�T1��]*��0s^l�
��R�|y�b���<-��]�eқT���#����0i�wɌ�~��:��UX����&'��^k;��~7�?�p���Ο~塗����v�����(������iߔﴃ         ,  x�ݖ�v�@���S���9}�ֽ�!F%g6
( ����HbL�&z2�9�>e��W�ew:<�>�t]C��9a���H����á=�7��r���9���JHP�ֶ�ʰ�w0� ����;���%�f��x^�I�iU7�=�u�o���1H�?�Hb��0ɞ���o	F�;��C>d��׌���R%=��5Ka����(�T2�<��UX�_�@��/"�q0'��8�&�O�0���ڪ�Nodda�h�l0\.d^��G%��i�%�}-����~(�7���.)R��{��id��`���QYG���������C	�dГ=W�6�Rbn�0 ����,$_���}���K#��[-�6�G$��F(�{"�"#�(�JQ�I���kci9�//Q�^wb�n�
s}��j��^פ��r5e�h�fGW|�l����a���t>&^�˞�<���Fv�����Ԃ��i�O`���1�3׳A�n�a�1��t�t�O���!=��೿&İ�0�m�I�,�a�A;�����?��U���I�rZv܃1D\=�rS5y|2rx'ͿSg|����(e�0,^��Y;S���=,�kq9�CB�f㾰m���BB��A^w-+� S�awb�fF�����+}������j?��#6���9���F�Y�h����?ќ(ob�G`��X�@�%n S�U�H[a��E5σ�+���}�':�&ɤ�b������1�E���p-z٦$�)y�ivyZ;r`�Ʃ���vֺ4��G�5�)�2���M��YV��#��1����P(�uW��         �  x�͒K��@���_�pRUϝ
�CAҙ�`��/�����N�I/:���U瞤��{s�A����$l�+����͚�r.2��*L�k��^�KV~�{�X^t^��Ӹ{[��0y�S�NK�0D�iCB��uB�W���Z��f��#
XӉ��k���.ҧh�V�˼�G��W��@�SD+%#b�P�3u!ձ�<b*i�H��$9r���
���dۈ�����hVup�xrz=-:h�.�|�yd]�t���):Rt�@�.W��0�V�./u���_�w�����Q�����v�r�D�t }[6�e�w�xLx�M+����(X���^n�h��o.c�ޣ=�ܑ��ʳ`���i�/,MS��Џ-ۏ��j
~h�aW$q%�J��mCm��A�;RJ{�gYz4�i�SG��NS���6���N�;�8�M����<��������P-^r��'�<�i�}h��D�P�l��}"Zq�<��G}��X�}(=C�s?�_?���         s  x���K��0��1��7��@a�bbb�G9҈��m��ܯN�u3b*�T=��u�0�@�O��wRu�s7����Jn��jRe �1�A)�s�<�0,���>� � ��lt�g����c��!��ȵ9�]m������G������]���ήy7q����7����V V������d^l)��v�Y-~jg�߆η�2��3�5�q��F�Y�T�t�gk\ŧ��c3?s���BI �y��4ýZ�1�'-������%{)�r�r�����#�m�t�����,�t���r���tL!ԋ�<�6�_�
�JbWHZ�.��+UE3�L��̣f=͢�7�<��2�;-���AҰY��z�_P�M           x��T˒�@<�_�?0���7GQtD��(�
����{bcG]�����̬�,�kث�<4��i��a�4��hv�ô�G ��d�����+w�ʉ�)���<βx���Z��sZ���;�v4;��8����0�����˦����-+!�`NUx���b�*��m����\T�-@�v�K��%�����@�Q��nlJk?v�_�D�G�#�38ѥ�>����P�����ף�-:��#{�}P+հ�q��f��v'�/�f�m/�k&��ر&��y�D�Dľ�wY|���n:�!�݆6���Zͭ��a��#�+�H�n\�_�����5B'Y �V�-ȉ4�л�!i�0�]�1|g��:����4J#�^���t�5;�%-�=b�c���3��K��:�`qpNWP�^�c���~f�V9�Y�uG��U�YTA$Jg�x�t�T��w��Y�7����Z-6�̖�	���N9yl:C�X��
��i�@9��b(�ڀ�w:Dʪ�ŘL�(P���)����j�P/�          �  x����r�L�c���@;��,g*� ȇ�A��_c޶i����af~<������P8i�4���8�d�1[O-Ԁ��s�P���>3�g�}b��娯&E���-F����Z����ܳ��Ȏ[�uVf�}�6�v�R�/�}y� V���'�v3���r4�z������r��-��]�r�'E�^i�Ql���i�ó���<�~R,xWǟX q����[��X�SnpށV����Z�B��o�z�eלZ.�b�
MT�/�bJ��l��㸹�P�eT)�]������ہ�|�)L������
��U���qP=n�<�����dzt/�`������,s�.�,F(y9�w��	�\�9�[�{ ~Q{�KO	��v*Z��4%�x��������ĜW�s�W�X���6޵)�hAk�>0��q��d�U ���?���݄���qM��[�>T�ӡ>)�����L����LU��'����ˌ���?��m1��JJ�m���h��2ú��������Y�t�u��AR�L���x(�P���:z{��vٍ˼?O>� +���0�W;g�����ۑ^�Cj��5��q�a߸UB���&'��L�V��H������}�Ug�4�������8�G}4�W>�o�9��w�J!�<\lڍ�q7�I^�N��zŃ�'A����^_3����</W��&Y٠H=I�uҳᥚ���ŧ������m{����o�sP)�~���>P��Ծ\^��� #�g\����2����B�g�9�F���C�1< �fe�(;���[��R=��蜆أ,#�Oך��x5���� p���5�f-Q34Mk9:5G��)ҫ��~�K�?��q(��sH�x�_�A]����&�͆ʖ��r�bs"����Oy�� ��Ϗs��IO)��;�ċ���.���o�q�uD�~�i�?�AF�      "   �  x����n�0�����L��ƊU@�Nd#����D�x��S�͒ek���6�}�Z�n� �g�D� �-�*�sx�N��
 C҇���I7�5�g���i�p�t�2���"=��j���g24U�T!��crY6�l��w���*��l��{�B�5��U'��y�3FJU@w��}��@�I��d�)J3!ea�ۏc�8�X�6ޢ�Է*��އ�f1A��]���Fb�+ �'@*��d��O��j_ g�ߡ�E�4զ����q�a�i���0V����EϦi<� ��`_���UY�!bB�TȻJ�[4����O
����q3��[��K����ޣ��I���e�ކ;���=$�
6чZ�Zf����7�=%�؊a�ZW+���s_��Wv��      #   |  x����n�@ �����@�ܐavV.����Q���@�w/¢Mc�ΒL>N�)�v���=-+��*�W*���5ހ� �`s�~���L'6ð b� ��1�s��ymSc�%�"�(y�ݳ7��W��M���ܶ�8�OܤT���_�"bȥF�[q��I6��me)p5_{JƻG�5�Z��FLD�8���$��Ne�J���5���e ��(7Ob�j�bcv�.	�yq��᎜�QY������rR'��!��o����u�І�K��e���Z;��ŴJ�����9��V���ى�=�"�B��hE���g��;t���phM#'���}�%;1IY������ٗ�D����V|�	��	%N��      =   *  x���[s�0���+��IH�!w(
�䑃LoE��T@�_�w�;����i.�����}���n�0�[���*��e���������>��v��Yk%-��V�#03QS��2k��º r�J��C#�
�l���q��2�PjP�bW-'Q���۽[xJ�;�9>:2V*�m�7����qUWw����<�;�j�0�Wt�?l�����0��dX���!�s����'naL��Mf�K.��F'� ��Bb�cD�����;�+ӊ�T�@��tx&�qr�O�yLm�<W.�.^�.��un�1�MV�NfA�D�����v<��D��O��Ow�fS}��BF$FŎw�C�
���1�b �Ϩłe��:������.���X�^������'|�^�+�Sy�
v3*?��&^dX����=�'iJ�����G��'M-XՁ*��K�a0�Rsۗ���f��y�]���=ǻܛ�q���<Er��`eW�K�&h�t]�ulza0�Z ����fb�B�p�a���x��{1�z��z���{B      $      x������ � �      %      x������ � �      '      x������ � �      (   �
  x��ZY��j}��QO31U��#�A6�EET�'n�/"���7��5��h�ZU}oǔh��+'3���O��Td�jv��� �D;�-Ŋ�-��$��^.j<W5@�K��%9麂�d[`@�x5p��U={E��x�8�I��ɡ�60� �:T��vI14��<쬤��޿�����z2��ÁR6�h�p���@`1C�LsD��zSOOO��� �Ks� �>���u`�C=�f�;ڃ��^x��e�.�t��[]94������ϫ��(����*S1�P���N^ceD�9*��P�*e$�^��� \� ��yV;X���g��O��ksV�"��������pQ��;��Q(z^�2p��5�{}�`�
�����.y���"�	�*j�gP*�=O�x@�ZʇVSi�X_�j;�,۟S]"���*"fG�z8� ��E��_a�J���	�+�@MPA=����9<߽�C�>@�r7"1c�Y�C�yg�a_�B�� >��Ө��²�Q<5��鮷vY��4��Xq�����oj,����{s�B��i�Dz_��� /�zf�6���H&�h�i�u���D�0��}���l�d��:�唺��3RTh*!�bh�nX������_�iR���?�|���"OX���f�������O��W2cM���Z��}�C� ����ɸ��#�\;��������~�G�@�=���ˋ(n�j�Z�2�kfH~ O�#�����S$K��W��`�D��U�z�ŴQ��A�Rf�5��ˍ����`����n���3�G��N�g1���xK'�Qj�k�Ť�ir {)��+\�����#&����B��E���ko#�ՙ/��>Q 䡂c��i�f<��k���ZJ��:���:[�!kb�2�6�%�&�Y�F0��ǂovU�����k����k�hI;�gi��"Y��@Y�f�j�oӡ^z���M=�\ZԈ�"�5\	m�v<�Ʋ� ��t�5���S2^�\��oR�6qn�Oh,9A���jİ�6q���F�_,��2�����^��{�-�R0͢��͹�_�} 7G���j�x����x��[
�KK�ʩo�#֙��/�[����8�ye�:➀��:���e�ٶ�C�f���Y{LUz(Ǐ
�=�ݓZu�h� ��h���d0]L��жk�8�K�Ԕ~���
��>�Hg�k�sy��l(t��U�e:r�b�M�7*��,wN�VNA�3�0�:�������z�����|��h����֎=D����
Fݑ��c͍l����e�����pu��`�H�M�g.��7�j�@�P�J��kL4eMv�EN������{3䚣^�}ێ:�Ԭ��ܟ1����屹��vO��j��%�>[��%�¦w�A0�M���D;O"���n幷������ʪ���]?us��\��x�wå�7������x�<������ϗn�w���)Wj����i�~ʧ_+/�Y9?T����H@��e�����Z��<���6 ��e[/�*!����RK��8o�W�9���$�sk"�p@~H�v'ئ�vj�g��R�,�g�R��nuH����(or�a��l�&��ze��������L�Q�� �Fq��6cOK*W��<�8Gv���x�ؒ��w�B[�����Ѵ<?��б%D�w����Gb�ZJ��T�) w%&ȭ��0hW��� ]�����B��@�{G���q��d~R8��J��H�h�0�D3�����ێ�?#y_��X�������aS���e�E��m�F8 v��nj𰯈�?�A��I���=�p��[�_�;�/t�:�#_��b�Ǫ�Ad��Y���*���4��lP \�(l+��X�S�\�T�墴�X �5q��}����q�ӊO�����n;RC�{ȅ�2᪞Mӟ�j%��l���W�ݏ�J�w{���E��p��J��%*�s@a�(�e��*Ą��r \Tr-�iji��o���K��i?���(�1���bߋ� �As<�#f�MHd����Ѭy?��&���G{�?�|ʇ�̴4 ��E�Ȧ�2�~�k��;%��;m8_���G��O���K3�ٵoj�j�G:y�����7��3�Ǎ�[�]�:~:���`�}^sqpj�/��=#��7ڝ<�t��g���|���MU��,$���5doz�YV�;�5�����9��Me��Sa��,Н� ����|��,�r�qs��C|sx�����~W3݄�=�؞�U�BQ��`2?�q3g!,b�.���-��"m7n�wb�2�k�����=�i�f�	mP�BZ��g#��͕����!��
Ь�$7��wl�.��pX8X��Ú�`�j�R�MҖ��p_���%�\>������tc` *; �.���t
�f�$�I��߬�)�?��V���Z}�zmC�D]k��pk��dI�=��#9����Pr��)�(w�Ѻ���L1�8A��MH�z�^�%������t�=�Xە�E���ls������yn�XQ3C��k��Ù灁>8d"D��.Dcd5���l�Y�@���'���;����P��i���~�WGCdS
��h��ᾤ�y�Y��}�q�T�/�}��鿽�L-      )      x�Ŝْ�ڶ��YO���&}�! �ҪĊ؁""���O0[�RM͚uv�K���Ϙc�D6��b���ܬ��W�Z��X%���$iŢH'��"$�m� �� �(���� �(����D�O8��3�	O{������֨��T�QFK$�#N��&�M"��@��뉒f0��0��_E��Lݮ�z��'�}��(�p8��A:�咺] A�bY���؃C�$���_
]�����QO��(�������X�Z<���"ܾ
�<"�v��� ��'�8��Ia�Ϥ	�q1�%J8��:$KE�/�ȋ��UKn�6J��.	�!��n"���J�w3OD��>�0�/�bӾb���c���E }�	��>k?���}X�4�ٵ�b�AՐ�b���|�D^X�"�Ŏ�w9��SO8����'zU%T�)3]���@�;��9�]J`����J8�ޱ�_,���ݩE�P;H��@ܱ�_	a��h�7�eV�F30�C ��Š��%��)���p��#
�hu�M���q��N��f�W�>W֪/��� ���΃�X"�o���Z4��B�>����>gNw��g���	�tS���>R��=�^S�b�5�*U��%��id�.����W�k��0�BZ�̵m���4�o,+Ԓ��}-駠{��7�o&��.ͭ4�&������u��$lI8��^�f]��6��I/��$&�rO6��Y�{$��/���3���
��Ц��:u�C>_�c���Qj�Cn��%Y;��D� �/����s��,�BUd?O�%>��a����L��`�[i�^�oK�|B�lg=�rl��t�e&��Vd5��n'��)�X	ߩ�4�w�y.~�mu�I	މ�%ڍI�j�2�=�;����d���������]��ۣ��k�і�Oث��Q*����ģ\R >���`�˙�w��]�"����CO^7d9��/�y�+���3y��1����Vz��l�\HҢ�A7EvL�l��y�1��Ӈt� Ӥ��dZ������d��mk�~`},��j� ���-2�˹�Ջ��u+G��#��D��4��x��$�+ЅO��Bn�9�����Ժ?2P��V;��<A�QgR��0�EM�7�`���fڤ�(�&;�=�_� �B�)>�aV�ϖ�~��E���s�y�ρ��VxB4��V �H����%�k�7�`������'����Ju���7�e$����k"8�8�%�7e�$�#T �p#�sު��.@�W���=_�ϵ�?=D�l��%��yG�8l�"����;/!C��ʸi6��qs��Y�}�����]��3�2x0���Ar�N����l@��V�3�ۖ!⊾8L�Y�u�� "��c�{{���}[ ��KikK����S'hSb� �2���c�2�c���� ��0�op�}�2��Cl�-ͬ���$��xC�����'`��3�nr����{��*��F�e��*¡p�؍8����n{��;�, �-�D|O�� �	�̷ѻ��J#>"x��w
;�g����:�l�����%�a���W{~eP7�9J���`�]����H��P�Cc"V4����e�����:拯1���j���ܶ�f��rS��-�Z(����Je�m�LOJ�����d�V�ø)�����N���S���Og��`�ڥsc�ƀ���?���pz�P-�������'lzCtq�_�S�$ҕm�e��݌���=��t7��q�r*m��V�q29F6*[�H{�l����vI�D�DQ~tӏ���:�5ϳ�7;]�Xp�{Gk��w�z�NV��V(&�a���	B_X����M����|ޭ?6�g�t2�7��+��f��%�[���;��d�U�^��Cz3���+��G*�4��+9}��o�k���X�w��4Z����n�0d5�ֵ�3T��9]-M�%D�1B�Z��p����&��B���T�Iٝ}�Ɵ�فe5C�V��]�o8��<��ǽ�C:����7�����E�;rm�Ԝݢ��0P����%�U�^y���`5E��h7_e�c�βw
��\O�鱓�#��m�R��h�&s�������mm��M:�r�oo�����V{B�R��Һ����~�.e#g��>����[�?�o��	=f�a�S x[dL���0Na�&c����$�>��փ#���������ć炈�g
��g�1f�Y/�wd���m�}3ګ���`���'�Ƭ�(h��͖4/�qcW0�A��JN����g��S�	�u��6��/�=k�3��r�P+퐨HB0�Ri������R��g���	�V��~$�yj�/���Ѣ΂��Q�̈́���r�W4�b�ɨQ���~j!��y_d/_��!��������$�����vj����I`=���������v����a/u�/�!� ���G�!�1洇�v�]'p�e[G��4�U5�Iy�i.�v���I�уI����~r*��^�0�,I!�����A�2��S�Wd4�^Ϟ��Z��xF��Ę�^G�������8m8f?�7S���ߨ�k嵡�%����B�z�#�R��(,(c̥*vk�0������H��Wh��jcE�{��xa�*Z��ZM�,�Mm��Â�2�w��Ԯz�6Ehr+�[�h��&۬+��#ɏ��XTR��R��4�z��@@(����ei�Ǫ2Z����tG�8�j���W����-|v6΁��ݦ����nTӔ+'��mo��8���L�c� n��兌����_/jK�lw�6L��J��ҽ}�E�(��AYZ�R�2��%�����ub@	4�j7I��&W���Ew;���O����3:�jꢹ_�P�=˭`���r:����:�8���Ur����QrL�͆�@~mD�:7��+XPWq)Y�u2T��(�W����bP_%Cv1] ���ѻ���b�����L����u2TK�~�׃}*�"�^ �TYpW��1k���Q���6}������'S݊�iʺ?�}���q�ӥ�x:`'��`*7�]Zm�\�As~�߀��{�|�"5��ѳx��� 5���j�W���N���Q�̓粍���y���쥯E�:g<L�:�B�'��3�5sX��}����ܧ��������/�T��?`�(�lX�]�/ikM׀3��.�~���O��|�U�K��u4ԅ����*Y8dH���U2T�nv>˨�6�I���w �_)Җ�k�;l;ļ:_*�^ٳL=ꇡl����3T��YK�:��C{.��3d�&:K,�z�� ��jB=hI��e't��7��{��UIa_+��+� *��x�Gϔ.52�5HoM�o:��X��ݾ9��=���c��]jh��._�
��Y<�Η���+;T�F��Y��~�o:���ʒ�&/�nH7�[v�lAS�|����"-&�RY��0�љ~�&��J�vӳ�5�6Ù��b��K`��H]�p�cqN���=���6���~S�vE����y©ߧ�#M�F������_�F�����Sw,k�$�u�6<�������Nh�\�X����9x���g��(nbC|�9|����px�Ap���Xt�J#<J��MpaI�x���n�d3�A������o����t���p��n�^⾛�@��!��JU�9����7���jeZD�k��y��^|u�T������a�46��_�I(ܣ�ut@A�I�FY��VYu��,BC��$m3fK����"�����q%0 e%�YoU��H�=zCt��>p(۠�V���k�f~=�}��ZA�2�,���2/	��oQ��IJ�?�|�Ջɨ�̄�=���"!IPȂP�Z`������&�F��[�#�M���i� �����Z:����F�B*7�]���v]3n�Fc�q߶�ƴ��P�F��i.�}�����c�B1���̕H��\�0�l�v(NcT��&���f�������v��J'ؤ�|Vo��N=0Z�sKL M  $�R�9�LP�]�#
��:Y��K�'3PR��Mk%���DĹҵD�x�N�d練N<_0e;��5�Hh̀-��N!�W��P�!�!�}����غS��edPVfNv��]����8�Nǧ5�	(kb�f���$�l�X�7K8�'���tφ` �m2c���=�N�Eِ�t���m;����|I,�˛H���3���t�y��yS�P<aK�3u�I%�ٹLV���.���=���#/��	 ��� �T�S[;X��;���8�eO�$հ� ��9�d�OGA�k7�a� �~��/�_���^P�����fl��X��s�)�ٿQ(��$B��ÙTc�tn�p
�g顓��`��Ա���
�g�iT����8�v�I���,=��6�A�ZC���0�kۀ�oG�E1�?$Mc��ZK�-��=��a	�#4N�y(�����jCO~��>�,}�o�ݩ���2X8�!��`�u�o�p���a�Y��2�'=c���xO��,�KԆҥ�y���#a�-ԙ�!��f��eP%t��t�mL�O,����P��b9�SF� t���,�=U�����.͖��*!�_���(��?زa9��B��R��5�o�0X7 ���D|��Q(�H@����RD����T�˽�L�ʹ,�EU����u�R8C����3n�P��	�7�}��b)�i���=:�i�hyE�G�qg�?kV^��e��4;7��x/5;���Þ@�Y��f;�p��K�CI�$N�=�Iw�O����K�����;�CM�h�W��w��`�o��gda�Lf^��͢5���ON�.s<��?�Pi�Lh+�by�|ԕ���򺱦m}u���F����Y��a��	��|�������3\�:
����^-b+_C��gz哥o�EJ��L�A�4G*�ߝ9pe�)g��PcC[j�9�:(��?�s1�h(;@�'9����^��w�~�8������w�vO�'On��Gp���>j�XC����؆d*�F#j�;�N���{�g��@�d_\	���u������Y���������SΦ�^�ʩuW����#��^�KmJ3Xw�zg�Ϸ"�17]�a9]le��Y��f�T�Q5�����a����� �W�e���Q�:-l�^�cf>��ݚ������B��>&���#��뢄N����VԂ^zx�J�(��D�U$Ko�
(�߇�6�m��L�Q�?�ş����3�ꤣ��3F���"�;u� o��t�F�@'N�xU�U46���S'���oW!ܬ`?�9`D�ѱd=�z�"w�<�Aػ-�:��Jj���;v��U���瞰����?���%�?D      +   �  x���ْ������b�@u�3Ý�(�2*F߀"����7z��>UeEUE�%�Ԉo-2W&C>�;yI���{ � d�o�)���ܞt�����N�,g� ���AL֫�������v�' _`8�
$�Jv���x��"Y�?0���M��B�Cw_ ���3�=���x��	�� X�l|��i�6*�'�|�nMi5I]@,�������E��$f����;��������xD?����w����a��8�}\U�&
��T��2��D�҃z��lwU-R��6򄤠���vX#�)�@�'�x��2��'�<�g�y���?��0<
��i�,$n�?�l�媿��5yR�s�K�`fO���kভ'�}��ِ��������� g�K��\�P�	�-oq�x{{�ɐ%2����j� ����l�(C�׮�rн+"�AK� �l%uz��
�2_:v!���83+z��T�3+�����K�������c=�/�56���H��8����T�������c
Ռ�pш�~��]J�Wۋ�e����HP�C�6�YXG���bq��j]��д��z�m`��zzz�o�}W�L ʺ�̞��vQ�gXg�I��tL�i�!�"�Z�}Z��M0�4Q��N�������c�Ƴ�E��ĩfo�4���F#4���>�6X]̏���B�-���Щng�e�-��6_lY�����P>AX(ҁ<ҕW�m�r�8�6�F��*�rS'���2�>��0u�x^��x���6��?s�g�;�tZ�����?�s?�c?��k7q�Y9��r�L�L���J�ϴ]*�D�"��T�c�}��~?H�'�WJ��=�o���t�\�������~'�mq�V)�8��Ja�Q�)qNZ\�m�� D��!��F�Gp���8�1��7ziM9
�]u����*46��N�N��V*ͬ��OѩW�!�KJ�Y�H�L��\�U�*�l���"_� �Z�`۸�e^�q�+܏rgĽ�f��W����z�_�i��rm4�2���B�/,�v8�h�,U�ӫZe�.��e$�����s�®/��f�tͦ��ʨ�ԏvdߙA����:d9��[����Aփ݅�1cߕ���_�N��1�1��%���ud���ܒ�����D_/j��X�h2��y�w*e�T��[����e�����}z��ǭ�#�L������þ(��K��O��p/��G�Z��.b�ش/u���7�i7և�'2͍�']W��nLx;�~}��G�[�P�m+��w߄��&�^Nx }�_D�Q73��}b�v�G�3s[�0�`,�TM�{��qI5�ߟ�^�����2�]��]g�|����V)�+���N��h�>��=��v=�0�Ef�u����~�;be��2k��T]�[�9�����@�B�&�R�D?�J�W������'n#����n���x���<==��9�      ,      x������ � �      -      x������ � �      .   �  x���ɮ�ȶ��w�G�����4��Ag�imc��߼ҙԪ��*)cg�>)��
�A���}�JM�S0��;���o�Q�����������o����㪆�Oh1*Lߴ	��k�"�h�lg���7~���!(�Ս�|��%����z'���&��Fx�g�rb����O���l��L#Cu}� 6���8�������9�㪽�y,���:���Y��my�������w�_:��K[K����w���(|F.�T���\�Ec���"��_�[b�����?���F��ҪKmE���x&/��V����j��6�$j8	ee{E�͇s�\ �gjН�k�P�q��O� ���ޗ7b�t�xج�.X������=��c-���y���s��	�͹vO�S�M�ƀMj�K���=	���π�7:�2]\�ݡ�����y�xc�g��k�k]���5d�h]���	��p{ �OԠ2��E7ş�c� 6�ǰ�M�z�YY����C�UU�y�f[��0{�������O�~��M�6��?mewQg�ؗ�����e'���Ic�w�]���r&`��V�~s���M��|%?��&t�;Cp��qĄɲ�	��t6Rޢsٴ��I��vON���O�<lRSL�����Բ6؄b�߯��5��O`���~}���\�����z����?�σ]ѽ׭{FZ �.n`t�i��LDj���!g�NS��:H��Kk��|T����0쟸B�s�����	�?q/F�M9Jb�B��쟸�)�����X������z���U����}<h�YG�~GŸ�֡/,#R�.���k��5���6��1�<��<�ǋ:Z�M(v�."�5����WW �P�}�M��TDiڼ��	�>�}�����ף�3����ԟ���Ǧ�9�=<�:j ���5��ڦ.'D��ɀ����\�:r�c�zů� 쟘��S����K�rw���.+�{.qO��e�k�?���I���}����Ȅ�m�6��|-N�]�'�Dqa�?1{ߛ����S�/�� ��йDb��`oue\�#`��U�7'+[��s�7s�M(6x���Z*׾H�`lR��UOܙ?'�	�z�.�A����&`���s�t�"���T�&)�E{e��zot>lB�o:���9�?X�ؤ��m.{������F&{���	�le��FlB���YF�0����\G�&�=�<���_w:6�X��yn{�S�ߪ`[��u9�kKݾ
���[k�6��M��w��5�7wL�s���u1� ���_��!�x�٭_j��Pl���fk\Y�W �P��޴�-��TM��Iu����y�c
�WQπMj���Lf�,��6lB�/Uy��x����u�&�kJ�
FT�o�W�؄bw��r��q�c�\�PlJ���2��u5� �o���w�����o����P��������86lB�g��ke}�U�z�&{nNW�k��~2�NlB�wTQ�3����;ؤi�~vԧ�yz�&u�1�Y��K���6��%-��F�جO�	�2A�ƣ�,�u���	���͹t�C�B{\ �ԓ�2O^bv���`�m��5,��V��.b�&ۼ�%]��F�[�� 6�Xߡ�c�Uʥc_� ؤ�ڃ.�g�����T�M(��B�6G9�6_� lR�;����Vu���?�24�+ft��W�8�Mh��*�e�^<��=�i�&��P��jMO[��MG6�X�n�`�_̬Χ}؄b��'=0�U��m�&5�[���?.�g[=`����
߭�I�Efh�M�|K��i���Eؤ��i��a�
{�x� 6�	z����i�Z_�&՗�7j*�޾�{�lB�EX��d����؄b���ar����b[�Mj��ϓ9r�y�(VB6��nd�a���S�_`��=�{C]���陼�6�/P�Z�hޤ�c�PlB���h��hy���E�&u�2�b<$5���؄b�c�~�i�3�i��&u�-#Y����5�X�&�3[=$�u^޵� lR�+��-Y�� 6���w*K��t~7`���'�:����r�ylR_���݆�#��&`�걩�2�d���$T�M*Vy�iR�A��^lB�YZ�vQ�Ns��I5#�$���l���IMܶ��0
���e�MjQ�]�i[��->_��I-jlk�����3`�:$�"��y��㇐6��Z�
�]�]gO�~ lRs�m�io�#7^�����ɸ�u�\�ʡ �Pl���!0�h=U`�:8��}������lB�G�m�e�mxy�
`�嬍�d4-��3�[�&u����ٲݐY��k�>�m*����`�����׮څTylR_���лa��J>�&{�^m.��@}��ؤvj<�����tk�"�6��˃�<�V��ԅ
ؤF��;-�ğ��X6�EM����$�/��x`���}R������6���v�w�g���_=2�c�J��h��a�v؄b�UjFΘ��Ro,`�Z9�xf�Uu�̥d�&u��kr����t��Z{ 6�f��������r4x�I�y�5X-�N��W5�&{+�o$f�fP��:6����ތҹ.G}��.`�z��B��䓕9��� 6�f���bM磖���6���3DKp��k�؄b�چ)`���Z�&�v�Ÿ�2���K�ؤ���A�Y��^&O��	�6I1r���O'>`��.�m�&����|- �Խe�[���`כ�M�����G.�#3��JlB��\lbG��q�~-��Tǧ���t���M�ŀM(�řUJElnߵ�3 �P�܎M�(�`�:����H6drcM`}}�؄b�V�Pw�����&���ǫ{�خM��ؤ�E��L�Ǟ���^6���+\�ZT�Bw��Iu�a��|�6'\\�&�$����~/K>��ؤ�dfޤ�dFZ��;`['�*�w�q����	�&��J��#WK�*�&�+'����s�<���v��~�2ʾq��m �P,���Av|�*�?6��^n�G��{�~��I}o��8T�s(<[���P�yu������XKlB�w���֣�ص�2�&���n���8�!�f��'�������}�2	�$��>�o�e}/alړ���gI�9˕HbyTSɝ�tl�]
�?Q]�v���z]�_�5��t����y�� �'jP�|P��\}�@�n ��^������8���x��P절�Tz���}�6�N����k�lR넭
��<*s5N�M(V��y﹪*k6��q���:JE`�m� 6���Tm�p*kU�_�`�Z������,`6sͿ �P�mI��5�ce�8lB�c,�۫?<w�%:`�:l�:]g��;���f�P,�p�dS�)�Z�6��I=-��������I�
��m������s
�&�W*t[�Ҿ�疋q؄b?fp�n9m��^\ ����<�ɺ���1`���I/��̖�7?l��b�C]�Ek��>�秸6��/�&��^��~� ��ˠ����:4 �����������@�-�      /   �  x����N�0���S��^v6�o�1�������Ё�0��N�(��49I����ɑc�K�o-���SM���J�S Q�f(��,�Y&��X���r!����lFq1m���i6o�k�a~DOj�	�t-�f9������hd?X�d�<�`���J����C2�w���k�A�b��*0f�!���p��l�����iB�b9����J�r�=uλn��5����
�پ�Xqh��]�y��w�׈.��K��t�v����
���0W��n���yn��N��[P#'����}A�̊3W�6%��U	өЍ��;m�N�����c�c�0�g@`�9#��,2�9��4*Z������P��9�����ǻ��ǚ�=Ļ�      0   7  x����n�@���)|�,�s�U4.��RBL�EtP`��*<}����\�����3>��Bsv�V�c ���-#��x�<�|�(y<��&2���x9`a�A�V�h�;����F �\�F+5�S�Qb\ۀ��޻�XAl+2pA�:�M�i�G�yT^�[�M��C�1U`�>JO��D1��.����fT�("7{�QVt55�+�@��ZB��k�4Y%q*�?�A�Չ�SS����@�!B�J�^6}�������=�Ǽ��Qe���j�N�f<NܷRg��m����>�ي��Ip�h��ۋ�$I?���      1   �  x���Ks�@�����*���P��f�o�&Z٠vTD0�����Gg(���*��{��
�}��4�qN�k �Rte�� �Ͽ%�� ��*�뵠�i�/�8P��I��:B�ufBqn.�G�︷�?����D�Ȋ��h]�JҎ�j��ι���/���� ��dM��]�o/9✫�/ѵ7��E��Y] I���&O�2"B��칎�3�H	:~������72J����vy���S?XJPX:�=]��-���@����[�+ڇ�c4�/c�D��b���ǈŨr�ZKz�fc5�;��/TD�5"Ũ_{L��&���p\�R�I�R*��?��z��EVM���P��9rGy�-���Z�(��M��j�ʬ�9�B�`�X�\8c�t�`�(�iK����|A�[�t��i�"]��=��ᥞT�H>�ra��`U}m��7��H�H��]��>�Ͷ�O���
<a�HL0���DE�gWi|B�	���A��c�Q��p-,J(��̮XuT�U\�2Q���W���\��z�0Z���ˈQ��R7�Q��F���Q{(k�x��r��¨7�5l�^7>q5��=�r9�W9q��������l��=��^��n�V�nok�9։>���g�T�S�!��q�����{�xF^�z�_ �����+x�1*��F�^�	��^�J�p��Ӊ&�7#����cw��UOi�(���?i��@=��s�bY�L��x�|?O��eMJ3�'�.
�?���D      2     x���ɒ�JE������I�3Œ���N�R�FAl���H֫�W��4�F�ر��'/K��̣���q�i�������]<�Kx�G~����	#���A�h��� ���ڐP^�����\K`?}�:��$�p	xN �B�������+H&w\�k.����4�W� z�)��p�Dy��C�ȳH�����O�D	�����MMD�^u[X�KOJ�����2�p|�o�8�=ݘ�z}��C�EE�yo�h'h�ɗY�E�N���� ~�����G�E!V��L?�JY[ja����.�؆�"��lE�M\����3>��V�]<	�)��֟���������m��1��4�i�9w�Re�ȒGۘ8E��C�ȧ��A���=�l�/��FurBq��t:�f��Z���P[���/��
���s�B=̆���kv"S��S�x�����g�Q�soC����Ű����m��Ȗ�$,�����~���9����
�_�<��yN��������.���"�*"m(7�����;�/��f[�pw��ֹ��4�N�S&jiƝ��=����t� Q\_�f-E]���������yEOd����b�_M�Ir������2b����x�sŕ������u�'e��u�Hy�E�h�|�v�*3�P(�Z�='�laN���s�ec3��.yB��:�]�<�VoPiA��K+X�8���1ϰ�9��\O�Q�hG����s�g���Fϼ��8�ذ]�>e�	���-�;��3l���~�Z��h�,      5   N  x���ێ�JF��)��SUP��DPN�(���Q�QZAE}�Q�����ĪtbBbb��?|U�t�]o�&b��{m� �u6���:d`��W�S2�V_g�g,+UX�t7���^��L.�T��`Ϡ7 `�x<��
JI5Lwc��A q߁��o��1+#��p��P9���v;@4�/-�I�*�&�Q˂m��D��A�TXb$����ͩ-Ө�bt��N�t��8��zcN1����9G��s��Z-�ߵ�j�(�~����.Z�j���M�؛���7m0K�H�	Q�����ֵ�V$`k�8�W��_��KZ0���;N涻s�[�qI��S�����r.K_�$#��Rpl^�Sowu�{ǵ5-�园�����c�
����`3M��.˚/���zL��O0f����`p��z�]����T`^���,@���{u�E��RS���ߌ���9(�`0,�X��!�ԼP�c�Q�,l,~=^Zpͤ��Ap��u������&PY��}Z �)���؉��0i�*��QG��G���ov?�f\Z!�E{ �פ��-;(Ӄ�\�˗����}���"a��{��C�eA�T�/ʐk�""�caw��}{ 	�� �O�LpN�]��nH��X�Oe��Ђ9�GBװl�+,
�&�>���d,����Q{����w��Wj�M�$&_J!�Q����tfI�+ɶ�E�I3���d͐d$�M0��'�Qx�r�k~Mb��Ԙ ����_L��f�3}k��v���ME}/��yy�߯&j!�8C;�S].>@��E�g�"8@i��N�������8݇��[���	�]v"      3   �  x���Ɏ�P���)|�2w`�w�\E(�E��dP��|��1�Z�.+�<�/���X�a9JJ>[��W
�\9�瓶~�`���d��U�i0����l�����I�q|����&]D�����:{X�[G'���P��!�e�=�Q`��&U6V��)5�=����[H���|�1���1Qb�<w�\�wp�ѩ'��ȶ�W��r�կ>�5�N� �)T�Sȃ��A���j\z���WZ^f��gռn��]��2v@jo�FC���@��QE�d�|-l 쉯x;/�|d�2�}���2FV���#��0#��G|��/ź�H(�RU{���>O-�*gK/@��׃�.��	��ѹZ�,S�?E�K���L$�on�r2
Y)䗾�3����Ϸ
���?�����J�xӰ�|����8�bȰ��G=�@-e�T�|�-|��꾾�'�>u��MbO��_Ka�2,��G���� �j      4   J  x���ٲ�X�k|��@R��NA@@�JU�"��*Oߨ9ʉI�-o��c������5�N=Q��6��?R3^��A�"���xPA�e`���)܎�IA��4�r�  K��P�<�V�b���C�ձ��Ju�W�pܺa-jn��:x}8�Jݠ&���BA/�����կU"��W�ݮ�ZpX�h�Pض������e�5�u�1�F���	\ѱ�j�m=��EwԟP�-� z�M�
��it	Yғg�-�p�?PE\���������Y�v��tr8	,
�� =j�q�*q���Y�_X�\Z�~tΞE��y���_����.���=ю�\��A\�E�@bm�^aW�H��˟Bx�%H����h"�C����eU�H��)}~'qQ	��\	e�0y�{�O�3Y�h�E���k����@�_��`&�Y�[Êl�D\��x7��Y4��UYN@|���a��`��Ȑ�M���,q�2E��w��Lp����4M�_�#�Z D��}���e�Qk����rh���:�l��N?����|PU�֣�BO%ޙU�Y\|WG�@��vA[�
�/o���j*_��@��h�ja�P�e���0~|�ԍ�[���n�e��@�ǛU4�,h,��VN��7������T��J O�+�#wtJ�dK��m�n�p��E�7�S�:K�!�O�,�l��~�ªA��9d��'�8�}f�8�js��mŢ��iۃ�kL���� �}�Y�E��q�>��F��O6��qL��l,��f�Y�yb�z5c@�� �ѱ��NYS�9�I��I��	)-��Uw꧈�!��M*\Ed��U��h�A17t�Kt�K-�Zj�w|��r�(@����%�{�0��>�x�ݱ�}��m9p�͓%��S.s�S$�F�Y�8}���)���m�'�sG���a9�q�qA}je 4�.�Ģ�xE�����[�k��,�������|��������)����y��Ő�Yp:lU�s���ژw�~6Y�d����c~��?f�[�g;��e�H�ru~<�v8�g:p�ˏ�5�\z*E�.�ω��yj��^���E�>�c��Z��/���     