import { eq, sql } from 'drizzle-orm';
import { alias } from 'drizzle-orm/pg-core';
import {
	handleError,
	handleResponse,
	validateRequest,
} from '../../../util/index.js';
import db from '../../index.js';
import * as publicSchema from '../../public/schema.js';
import * as zipperSchema from '../../zipper/schema.js';
import slider, { stock, transaction } from '../schema.js';

export async function insert(req, res, next) {
	if (!(await validateRequest(req, next))) return;

	console.log('req.body', req.body);

	const stockPromise = db
		.insert(stock)
		.values(req.body)
		.returning({ insertedId: stock.order_description_uuid });
	try {
		const data = await stockPromise;
		const toast = {
			status: 201,
			type: 'insert',
			message: `${data[0].insertedId} inserted`,
		};
		return await res.status(201).json({ toast, data });
	} catch (error) {
		await handleError({ error, res });
	}
}

export async function update(req, res, next) {
	if (!(await validateRequest(req, next))) return;

	const stockPromise = db
		.update(stock)
		.set(req.body)
		.where(eq(stock.uuid, req.params.uuid))
		.returning({ updatedId: stock.order_description_uuid });
	try {
		const data = await stockPromise;
		const toast = {
			status: 201,
			type: 'update',
			message: `${data[0].updatedId} updated`,
		};
		return await res.status(201).json({ toast, data });
	} catch (error) {
		await handleError({ error, res });
	}
}

export async function remove(req, res, next) {
	if (!(await validateRequest(req, next))) return;

	const stockPromise = db
		.delete(stock)
		.where(eq(stock.uuid, req.params.uuid))
		.returning({ deletedId: stock.order_description_uuid });
	try {
		const data = await stockPromise;
		const toast = {
			status: 201,
			type: 'delete',
			message: `${data[0].deletedId} deleted`,
		};
		return await res.status(201).json({ toast, data });
	} catch (error) {
		await handleError({ error, res });
	}
}

export async function selectAll(req, res, next) {
	const query = sql`
	SELECT
		stock.uuid,
		stock.order_description_uuid,
		order_description.order_info_uuid,
		CONCAT('Z', TO_CHAR(order_info.created_at, 'YY'), '-', LPAD(order_info.id::text, 4, '0')) AS order_number,
		vodf.item_description,
		stock.order_quantity,
		stock.body_quantity,
		stock.cap_quantity,
		stock.puller_quantity,
		stock.link_quantity,
		stock.sa_prod,
		stock.coloring_stock,
		stock.coloring_prod,
		stock.trx_to_finishing,
		stock.u_top_quantity,
		stock.h_bottom_quantity,
		stock.box_pin_quantity,
		stock.two_way_pin_quantity,
		stock.created_at,
		stock.updated_at,
		stock.remarks,
		vodf.item,
		vodf.item_name,
		vodf.item_short_name,
		vodf.zipper_number,
		vodf.zipper_number_name,
		vodf.zipper_number_short_name,
		vodf.end_type,
		vodf.end_type_name,
		vodf.end_type_short_name,
		vodf.lock_type,
		vodf.lock_type_name,
		vodf.lock_type_short_name,
		vodf.puller_type,
		vodf.puller_type_name,
		vodf.puller_type_short_name,
		vodf.puller_color,
		vodf.puller_color_name,
		vodf.puller_color_short_name,
		vodf.puller_link,
		vodf.puller_link_name,
		vodf.puller_link_short_name,
		vodf.slider,
		vodf.slider_name,
		vodf.slider_short_name,
		vodf.slider_body_shape,
		vodf.slider_body_shape_name,
		vodf.slider_body_shape_short_name,
		vodf.slider_link,
		vodf.slider_link_name,
		vodf.slider_link_short_name,
		vodf.coloring_type,
		vodf.coloring_type_name,
		vodf.coloring_type_short_name,
		vodf.logo_type,
		vodf.logo_type_name,
		vodf.logo_type_short_name,
		vodf.is_logo_body,
		vodf.is_logo_puller
	FROM
		slider.stock
	LEFT JOIN
		zipper.order_description ON stock.order_description_uuid = order_description.uuid
	LEFT JOIN
		zipper.order_info ON order_description.order_info_uuid = order_info.uuid
	LEFT JOIN 
		zipper.v_order_details_full vodf ON order_description.uuid = vodf.order_description_uuid;
	`;

	const resultPromise = db.execute(query);

	try {
		const data = await resultPromise;
		const toast = {
			status: 200,
			type: 'select',
			message: 'stock',
		};
		return await res.status(200).json({ toast, data: data?.rows });
	} catch (error) {
		await handleError({ error, res });
	}
}

export async function select(req, res, next) {
	if (!(await validateRequest(req, next))) return;

	const query = sql`
	SELECT
		stock.uuid,
		stock.order_description_uuid,
		order_description.order_info_uuid,
		CONCAT('Z', TO_CHAR(order_info.created_at, 'YY'), '-', LPAD(order_info.id::text, 4, '0')) AS order_number,
		vodf.item_description,
		stock.order_quantity,
		stock.body_quantity,
		stock.cap_quantity,
		stock.puller_quantity,
		stock.link_quantity,
		stock.sa_prod,
		stock.coloring_stock,
		stock.coloring_prod,
		stock.trx_to_finishing,
		stock.u_top_quantity,
		stock.h_bottom_quantity,
		stock.box_pin_quantity,
		stock.two_way_pin_quantity,
		stock.created_at,
		stock.updated_at,
		stock.remarks,
		vodf.item,
		vodf.item_name,
		vodf.item_short_name,
		vodf.zipper_number,
		vodf.zipper_number_name,
		vodf.zipper_number_short_name,
		vodf.end_type,
		vodf.end_type_name,
		vodf.end_type_short_name,
		vodf.lock_type,
		vodf.lock_type_name,
		vodf.lock_type_short_name,
		vodf.puller_type,
		vodf.puller_type_name,
		vodf.puller_type_short_name,
		vodf.puller_color,
		vodf.puller_color_name,
		vodf.puller_color_short_name,
		vodf.puller_link,
		vodf.puller_link_name,
		vodf.puller_link_short_name,
		vodf.slider,
		vodf.slider_name,
		vodf.slider_short_name,
		vodf.slider_body_shape,
		vodf.slider_body_shape_name,
		vodf.slider_body_shape_short_name,
		vodf.slider_link,
		vodf.slider_link_name,
		vodf.slider_link_short_name,
		vodf.coloring_type,
		vodf.coloring_type_name,
		vodf.coloring_type_short_name,
		vodf.logo_type,
		vodf.logo_type_name,
		vodf.logo_type_short_name,
		vodf.is_logo_body,
		vodf.is_logo_puller
	FROM
		slider.stock
	LEFT JOIN
		zipper.order_description ON stock.order_description_uuid = order_description.uuid
	LEFT JOIN
		zipper.order_info ON order_description.order_info_uuid = order_info.uuid
	LEFT JOIN 
		zipper.v_order_details_full vodf ON order_description.uuid = vodf.order_description_uuid
	WHERE
		stock.uuid = ${req.params.uuid};
	`;

	const stockPromise = db.execute(query);

	try {
		const data = await stockPromise;
		const toast = {
			status: 200,
			type: 'select',
			message: 'stock',
		};
		return await res.status(200).json({ toast, data: data?.rows[0] });
	} catch (error) {
		await handleError({ error, res });
	}
}

export async function selectStockByFromSection(req, res, next) {
	const { from_section } = req.params;

	const query = sql`
	SELECT
		stock.uuid,
		stock.order_description_uuid,
		order_description.order_info_uuid,
		CONCAT('Z', TO_CHAR(order_info.created_at, 'YY'), '-', LPAD(order_info.id::text, 4, '0')) AS order_number,
		vodf.item_description,
		vodf.item,
		vodf.item_name,
		vodf.item_short_name,
		vodf.zipper_number,
		vodf.zipper_number_name,
		vodf.zipper_number_short_name,
		vodf.end_type,
		vodf.end_type_name,
		vodf.end_type_short_name,
		vodf.lock_type,
		vodf.lock_type_name,
		vodf.lock_type_short_name,
		vodf.puller_type,
		vodf.puller_type_name,
		vodf.puller_type_short_name,
		vodf.puller_color,
		vodf.puller_color_name,
		vodf.puller_color_short_name,
		vodf.puller_link,
		vodf.puller_link_name,
		vodf.puller_link_short_name,
		vodf.slider,
		vodf.slider_name,
		vodf.slider_short_name,
		vodf.slider_body_shape,
		vodf.slider_body_shape_name,
		vodf.slider_body_shape_short_name,
		vodf.slider_link,
		vodf.slider_link_name,
		vodf.slider_link_short_name,
		vodf.coloring_type,
		vodf.coloring_type_name,
		vodf.coloring_type_short_name,
		vodf.logo_type,
		vodf.logo_type_name,
		vodf.logo_type_short_name,
		vodf.is_logo_body,
		vodf.is_logo_puller,
		stock.order_quantity,
		stock.body_quantity,
		stock.cap_quantity,
		stock.puller_quantity,
		stock.link_quantity,
		stock.sa_prod,
		stock.coloring_stock,
		stock.coloring_prod,
		stock.trx_to_finishing,
		stock.u_top_quantity,
		stock.h_bottom_quantity,
		stock.box_pin_quantity,
		stock.two_way_pin_quantity,
		stock.created_at,
		stock.updated_at,
		stock.remarks,
		sliderTransactionGiven.trx_quantity as total_trx_quantity
	FROM
		slider.stock
	LEFT JOIN
		zipper.order_description ON stock.order_description_uuid = order_description.uuid
	LEFT JOIN 
		zipper.order_info ON order_description.order_info_uuid = order_info.uuid
	LEFT JOIN 
		zipper.v_order_details_full vodf ON order_description.uuid = vodf.order_description_uuid
	LEFT JOIN
    (
        SELECT
            stock.uuid AS stock_uuid,
            SUM(transaction.trx_quantity) AS trx_quantity
        FROM
            slider.transaction
        LEFT JOIN
            slider.stock ON transaction.stock_uuid = stock.uuid
        WHERE
            transaction.from_section = ${from_section}
        GROUP BY
            stock.uuid
    ) AS sliderTransactionGiven ON stock.uuid = sliderTransactionGiven.stock_uuid;`;

	try {
		const data = await db.execute(query);
		const toast = {
			status: 200,
			type: 'select',
			message: 'stock',
		};
		return await res.status(200).json({ toast, data: data?.rows });
	} catch (error) {
		await handleError({ error, res });
	}
}
