import { eq, sql } from 'drizzle-orm';
import {
	handleError,
	handleResponse,
	validateRequest,
} from '../../../util/index.js';
import db from '../../index.js';
import { batch_entry, sfg } from '../schema.js';

export async function insert(req, res, next) {
	if (!(await validateRequest(req, next))) return;

	const batchEntryPromise = db
		.insert(batch_entry)
		.values(req.body)
		.returning({ insertedUuid: batch_entry.uuid });

	try {
		const data = await batchEntryPromise;

		const toast = {
			status: 201,
			type: 'insert',
			message: `${data[0].insertedUuid} inserted`,
		};

		res.status(201).json({ toast, data });
	} catch (error) {
		await handleError({ error, res });
	}
}

export async function update(req, res, next) {
	if (!(await validateRequest(req, next))) return;

	const batchEntryPromise = db
		.update(batch_entry)
		.set(req.body)
		.where(eq(batch_entry.uuid, req.params.uuid))
		.returning({ updatedUuid: batch_entry.uuid });

	try {
		const data = await batchEntryPromise;
		const toast = {
			status: 201,
			type: 'update',
			message: `${data[0].updatedUuid} updated`,
		};

		res.status(201).json({ toast, data });
	} catch (error) {
		await handleError({ error, res });
	}
}

export async function remove(req, res, next) {
	if (!(await validateRequest(req, next))) return;

	const batchEntryPromise = db
		.delete(batch_entry)
		.where(eq(batch_entry.uuid, req.params.uuid))
		.returning({ deletedUuid: batch_entry.uuid });

	try {
		const data = await batchEntryPromise;
		const toast = {
			status: 201,
			type: 'delete',
			message: `${data[0].deletedUuid} deleted`,
		};

		res.status(201).json({ toast, data });
	} catch (error) {
		await handleError({ error, res });
	}
}

export async function selectAll(req, res, next) {
	const resultPromise = db
		.select({
			uuid: batch_entry.uuid,
			batch_uuid: batch_entry.batch_uuid,
			sfg_uuid: batch_entry.sfg_uuid,
			quantity: batch_entry.quantity,
			production_quantity: batch_entry.production_quantity,
			production_quantity_in_kg: batch_entry.production_quantity_in_kg,
			created_at: batch_entry.created_at,
			updated_at: batch_entry.updated_at,
			remarks: batch_entry.remarks,
		})
		.from(batch_entry)
		.leftJoin(batch, eq(batch.uuid, batch_entry.batch_uuid))
		.leftJoin(sfg, eq(sfg.uuid, batch_entry.sfg_uuid));

	const toast = {
		status: 200,
		type: 'select_all',
		message: 'batch entry list',
	};
	handleResponse({
		promise: resultPromise,
		res,
		next,
		...toast,
	});
}

export async function select(req, res, next) {
	if (!(await validateRequest(req, next))) return;

	const batchEntryPromise = db
		.select({
			uuid: batch_entry.uuid,
			batch_uuid: batch_entry.batch_uuid,
			sfg_uuid: batch_entry.sfg_uuid,
			quantity: batch_entry.quantity,
			production_quantity: batch_entry.production_quantity,
			production_quantity_in_kg: batch_entry.production_quantity_in_kg,
			created_at: batch_entry.created_at,
			updated_at: batch_entry.updated_at,
			remarks: batch_entry.remarks,
		})
		.from(batch_entry)
		.leftJoin(batch, eq(batch.uuid, batch_entry.batch_uuid))
		.leftJoin(sfg, eq(sfg.uuid, batch_entry.sfg_uuid))
		.where(eq(batch_entry.uuid, req.params.uuid));

	try {
		const data = await batchEntryPromise;
		const toast = {
			status: 200,
			type: 'select',
			message: 'batch entry',
		};

		return res.status(200).json({ toast, data: data[0] });
	} catch (error) {
		await handleError({ error, res });
	}
}

export async function selectBatchEntryByBatchUuid(req, res, next) {
	if (!(await validateRequest(req, next))) return;

	const { batch_uuid } = req.params;

	const query = sql`
		SELECT
			be.uuid as batch_entry_uuid,
			bp_given.batch_production_uuid,
			be.batch_uuid,
			be.sfg_uuid,
			be.quantity,
			be.production_quantity,
			be.production_quantity_in_kg,
			be.created_at,
			be.updated_at,
			be.remarks as batch_remarks,
			oe.style,
			oe.color,
			oe.size,
			oe.quantity as order_quantity,
			vod.order_number,
			vod.item_description,
			bp_given.given_production_quantity,
			bp_given.given_production_quantity_in_kg,
			COALESCE(be.quantity,0) - COALESCE(bp_given.given_production_quantity,0) as balance_quantity
		FROM
			zipper.batch_entry be
		LEFT JOIN
			zipper.batch b ON be.batch_uuid = b.uuid
		LEFT JOIN 
			zipper.sfg sfg ON be.sfg_uuid = sfg.uuid
		LEFT JOIN
			zipper.order_entry oe ON sfg.order_entry_uuid = oe.uuid
		LEFT JOIN
			zipper.v_order_details vod ON oe.order_description_uuid = vod.order_description_uuid
		LEFT JOIN
			(
				SELECT
					batch_entry.uuid as batch_entry_uuid,
					bp.uuid as batch_production_uuid,
					SUM(bp.production_quantity) AS given_production_quantity,
					SUM(bp.production_quantity_in_kg) AS given_production_quantity_in_kg
				FROM
					zipper.batch_production bp
				LEFT JOIN 
					zipper.batch_entry ON bp.batch_entry_uuid = batch_entry.uuid
				GROUP BY
					batch_entry.uuid, bp.uuid
			) AS bp_given ON be.uuid = bp_given.batch_entry_uuid
		WHERE
			be.batch_uuid = ${batch_uuid}`;

	const batchEntryPromise = db.execute(query);

	try {
		const data = await batchEntryPromise;
		const toast = {
			status: 200,
			type: 'select',
			message: 'batch_entry By batch_entry_uuid',
		};

		return res.status(200).json({ toast, data: data?.rows });
	} catch (error) {
		await handleError({ error, res });
	}
}

export async function getOrderDetailsForBatchEntry(req, res, next) {
	if (!(await validateRequest(req, next))) return;

	const query = sql`
		SELECT
			sfg.uuid as sfg_uuid,
			sfg.recipe_uuid as recipe_uuid,
			concat('LDR', to_char(recipe.created_at, 'YY'), '-', LPAD(recipe.id::text, 4, '0')) as recipe_id,
			oe.style,
			oe.color,
			oe.size,
			oe.quantity as order_quantity,
			vod.order_number,
			vod.item_description,
			be_given.given_quantity,
			be_given.given_production_quantity,
			be_given.given_production_quantity_in_kg,
			coalesce(be_given.given_quantity,0) as balance_quantity
		FROM
			zipper.sfg sfg
		LEFT JOIN 
			lab_dip.recipe recipe ON sfg.recipe_uuid = recipe.uuid
		LEFT JOIN
			zipper.order_entry oe ON sfg.order_entry_uuid = oe.uuid
		LEFT JOIN
			zipper.v_order_details vod ON oe.order_description_uuid = vod.order_description_uuid
		LEFT JOIN
			(
				SELECT
					sfg.uuid as sfg_uuid,
					SUM(be.quantity) AS given_quantity,
					SUM(be.production_quantity) AS given_production_quantity,
					SUM(be.production_quantity_in_kg) AS given_production_quantity_in_kg
				FROM
					zipper.batch_entry be
				LEFT JOIN 
					zipper.sfg sfg ON be.sfg_uuid = sfg.uuid
				GROUP BY
					sfg.uuid
			) AS be_given ON sfg.uuid = be_given.sfg_uuid
		WHERE
			sfg.recipe_uuid IS NOT NULL
	`;

	const batchEntryPromise = db.execute(query);

	try {
		const data = await batchEntryPromise;

		const batch_data = { batch_entry: data?.rows };

		const toast = {
			status: 200,
			type: 'select',
			message: 'batch_entry By batch_entry_uuid',
		};

		return res.status(200).json({ toast, data: batch_data });
	} catch (error) {
		await handleError({ error, res });
	}
}
