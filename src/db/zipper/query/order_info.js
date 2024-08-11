import {
	handleError,
	handleResponse,
	validateRequest,
} from '../../../util/index.js';
import db from '../../index.js';

import { eq, sql } from 'drizzle-orm';
import * as hrSchema from '../../hr/schema.js';
import * as publicSchema from '../../public/schema.js';
import { order_info } from '../schema.js';

export async function insert(req, res, next) {
	// insert issue persists (insert issue)
	if (!validateRequest(req, next)) return;

	const {
		uuid,
		buyer_uuid,
		party_uuid,
		reference_order_info_uuid,
		marketing_uuid,
		merchandiser_uuid,
		factory_uuid,
		is_sample,
		is_bill,
		is_cash,
		marketing_priority,
		factory_priority,
		status,
		created_by,
		created_at,
		remarks,
	} = req.body;

	const orderInfoPromise = db
		.insert(order_info)
		.values({
			uuid,
			buyer_uuid,
			party_uuid,
			reference_order_info_uuid,
			marketing_uuid,
			merchandiser_uuid,
			factory_uuid,
			is_sample,
			is_bill,
			is_cash,
			marketing_priority,
			factory_priority,
			status,
			created_by,
			created_at,
			remarks,
		})
		.returning({
			insertedId: sql`CONCAT('Z', to_char(order_info.created_at, 'YY'), '-', LPAD(order_info.id::text, 4, '0'))`,
		});

	try {
		const data = await orderInfoPromise;
		const toast = {
			status: 200,
			type: 'insert',
			message: `${data[0].insertedId} inserted`,
		};

		return res.status(201).json({ toast, data });
	} catch (error) {
		await handleError({ error, res });
	}
}

export async function update(req, res, next) {
	if (!(await validateRequest(req, next))) return;

	const {
		buyer_uuid,
		party_uuid,
		reference_order_info_uuid,
		marketing_uuid,
		merchandiser_uuid,
		factory_uuid,
		is_sample,
		is_bill,
		is_cash,
		marketing_priority,
		factory_priority,
		status,
		created_by,
		created_at,
		updated_at,
		remarks,
	} = req.body;

	const orderInfoPromise = db
		.update(order_info)
		.set({
			buyer_uuid,
			party_uuid,
			reference_order_info_uuid,
			marketing_uuid,
			merchandiser_uuid,
			factory_uuid,
			is_sample,
			is_bill,
			is_cash,
			marketing_priority,
			factory_priority,
			status,
			created_by,
			created_at,
			updated_at,
			remarks,
		})
		.where(eq(order_info.uuid, req.params.uuid))
		.returning({
			updatedId: sql`CONCAT('Z', to_char(order_info.created_at, 'YY'), '-', LPAD(order_info.id::text, 4, '0'))`,
		});

	try {
		const data = await orderInfoPromise;
		const toast = {
			status: 201,
			type: 'update',
			message: `${data[0].updatedId} updated`,
		};

		return res.status(201).json({ toast, data });
	} catch (error) {
		await handleError({ error, res });
	}
}

export async function remove(req, res, next) {
	if (!(await validateRequest(req, next))) return;

	const orderInfoPromise = db
		.delete(order_info)
		.where(eq(order_info.uuid, req.params.uuid))
		.returning({
			deletedId: sql`CONCAT('Z', to_char(order_info.created_at, 'YY'), '-', LPAD(order_info.id::text, 4, '0'))`,
		});

	try {
		const result = await orderInfoPromise;
		const toast = {
			status: 201,
			type: 'delete',
			message: `${result[0].deletedId} deleted`,
		};

		return res.status(201).json({ toast, data: result[0].deletedId });
	} catch (error) {
		await handleError({ error, res });
	}
}

export async function selectAll(req, res, next) {
	const orderInfoPromise = db
		.select({
			uuid: order_info.uuid,
			id: order_info.id,
			order_number: sql`CONCAT('Z', to_char(order_info.created_at, 'YY'), '-', LPAD(order_info.id::text, 4, '0'))`,
			reference_order_info_uuid: order_info.reference_order_info_uuid,
			buyer_uuid: order_info.buyer_uuid,
			buyer_name: publicSchema.buyer.name,
			party_uuid: order_info.party_uuid,
			party_name: publicSchema.party.name,
			marketing_uuid: order_info.marketing_uuid,
			marketing_name: publicSchema.marketing.name,
			merchandiser_uuid: order_info.merchandiser_uuid,
			merchandiser_name: publicSchema.merchandiser.name,
			factory_uuid: order_info.factory_uuid,
			factory_name: publicSchema.factory.name,
			is_sample: order_info.is_sample,
			is_bill: order_info.is_bill,
			is_cash: order_info.is_cash,
			marketing_priority: order_info.marketing_priority,
			factory_priority: order_info.factory_priority,
			status: order_info.status,
			created_by: order_info.created_by,
			created_by_name: hrSchema.users.name,
			created_at: order_info.created_at,
			updated_at: order_info.updated_at,
			remarks: order_info.remarks,
		})
		.from(order_info)
		.leftJoin(
			publicSchema.buyer,
			eq(order_info.buyer_uuid, publicSchema.buyer.uuid)
		)
		.leftJoin(
			publicSchema.party,
			eq(order_info.party_uuid, publicSchema.party.uuid)
		)
		.leftJoin(
			publicSchema.marketing,
			eq(order_info.marketing_uuid, publicSchema.marketing.uuid)
		)
		.leftJoin(
			publicSchema.merchandiser,
			eq(order_info.merchandiser_uuid, publicSchema.merchandiser.uuid)
		)
		.leftJoin(
			publicSchema.factory,
			eq(order_info.factory_uuid, publicSchema.factory.uuid)
		)
		.leftJoin(
			hrSchema.users,
			eq(order_info.created_by, hrSchema.users.uuid)
		);

	const toast = {
		status: 200,
		type: 'select_all',
		message: 'Order Info',
	};

	handleResponse({
		promise: orderInfoPromise,
		res,
		next,
		...toast,
	});
}

export async function select(req, res, next) {
	if (!(await validateRequest(req, next))) return;

	const orderInfoPromise = db
		.select({
			uuid: order_info.uuid,
			id: order_info.id,
			reference_order_info_uuid: order_info.reference_order_info_uuid,
			buyer_uuid: order_info.buyer_uuid,
			buyer_name: publicSchema.buyer.name,
			party_uuid: order_info.party_uuid,
			party_name: publicSchema.party.name,
			marketing_uuid: order_info.marketing_uuid,
			marketing_name: publicSchema.marketing.name,
			merchandiser_uuid: order_info.merchandiser_uuid,
			merchandiser_name: publicSchema.merchandiser.name,
			factory_uuid: order_info.factory_uuid,
			factory_name: publicSchema.factory.name,
			is_sample: order_info.is_sample,
			is_bill: order_info.is_bill,
			is_cash: order_info.is_cash,
			marketing_priority: order_info.marketing_priority,
			factory_priority: order_info.factory_priority,
			status: order_info.status,
			created_by: order_info.created_by,
			created_by_name: hrSchema.users.name,
			created_at: order_info.created_at,
			updated_at: order_info.updated_at,
			remarks: order_info.remarks,
		})
		.from(order_info)
		.leftJoin(
			publicSchema.buyer,
			eq(order_info.buyer_uuid, publicSchema.buyer.uuid)
		)
		.leftJoin(
			publicSchema.party,
			eq(order_info.party_uuid, publicSchema.party.uuid)
		)
		.leftJoin(
			publicSchema.marketing,
			eq(order_info.marketing_uuid, publicSchema.marketing.uuid)
		)
		.leftJoin(
			publicSchema.merchandiser,
			eq(order_info.merchandiser_uuid, publicSchema.merchandiser.uuid)
		)
		.leftJoin(
			publicSchema.factory,
			eq(order_info.factory_uuid, publicSchema.factory.uuid)
		)
		.leftJoin(
			hrSchema.users,
			eq(order_info.created_by, hrSchema.users.uuid)
		)
		.where(eq(order_info.uuid, req.params.uuid));

	const toast = {
		status: 200,
		type: 'select',
		message: 'Order Info',
	};

	handleResponse({
		promise: orderInfoPromise,
		res,
		next,
		...toast,
	});
}

export async function getOrderDetails(req, res, next) {
	const query = sql`SELECT 
					vod.*, 
					DENSE_RANK() OVER (
						PARTITION BY vod.order_number
						ORDER BY vod.order_info_uuid
					) order_number_wise_rank, 
					order_number_wise_counts.order_number_wise_count as order_number_wise_count
				from zipper.v_order_details vod
					LEFT JOIN (
						SELECT order_number, COUNT(*) as order_number_wise_count
						FROM zipper.v_order_details
						GROUP BY order_number
					) order_number_wise_counts
					ON vod.order_number = order_number_wise_counts.order_number
					LEFT JOIN zipper.order_info oi ON vod.order_info_uuid = oi.uuid
				WHERE vod.order_description_uuid IS NOT NULL
				ORDER BY vod.order_number desc, order_number_wise_rank`;

	const orderInfoPromise = db.execute(query);

	try {
		const data = await orderInfoPromise;

		const toast = {
			status: 200,
			type: 'select_all',
			msg: 'Order Info list',
		};

		res.status(200).json({ toast, data: data?.rows });
	} catch (error) {
		await handleError({ error, res });
	}
}
