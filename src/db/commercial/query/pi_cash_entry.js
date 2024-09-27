import { desc, eq, sql } from 'drizzle-orm';
import { createApi } from '../../../util/api.js';
import {
	handleError,
	handleResponse,
	validateRequest,
} from '../../../util/index.js';
import db from '../../index.js';
import * as zipperSchema from '../../zipper/schema.js';
import { pi_cash_entry } from '../schema.js';

export async function insert(req, res, next) {
	if (!(await validateRequest(req, next))) return;

	const pi_entryPromise = db
		.insert(pi_cash_entry)
		.values(req.body)
		.returning({ insertId: pi_cash_entry.uuid });
	try {
		const data = await pi_entryPromise;
		const toast = {
			status: 201,
			type: 'create',
			message: `${data[0].insertId} created`,
		};

		return await res.status(201).json({ toast, data });
	} catch (error) {
		await handleError({ error, res });
	}
}

export async function update(req, res, next) {
	if (!(await validateRequest(req, next))) return;

	const piEntryPromise = db
		.update(pi_cash_entry)
		.set(req.body)
		.where(eq(pi_cash_entry.uuid, req.params.uuid))
		.returning({ updatedId: pi_cash_entry.uuid });

	try {
		const data = await piEntryPromise;
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

	const piEntryPromise = db
		.delete(pi_cash_entry)
		.where(eq(pi_cash_entry.uuid, req.params.uuid))
		.returning({ deletedId: pi_cash_entry.uuid });

	try {
		const data = await piEntryPromise;
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
	const resultPromise = db
		.select({
			uuid: pi_cash_entry.uuid,
			pi_cash_uuid: pi_cash_entry.pi_cash_uuid,
			sfg_uuid: pi_cash_entry.sfg_uuid,
			thread_order_entry_uuid: pi_cash_entry.thread_order_entry_uuid,
			pi_cash_quantity: pi_cash_entry.pi_cash_quantity,
			created_at: pi_cash_entry.created_at,
			updated_at: pi_cash_entry.updated_at,
			remarks: pi_cash_entry.remarks,
		})
		.from(pi_cash_entry)
		.orderBy(desc(pi_cash_entry.created_at));

	const toast = {
		status: 200,
		type: 'select_all',
		message: 'pi_cash_entry list',
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

	const pi_entryPromise = db
		.select({
			uuid: pi_cash_entry.uuid,
			pi_cash_uuid: pi_cash_entry.pi_cash_uuid,
			sfg_uuid: pi_cash_entry.sfg_uuid,
			thread_order_entry_uuid: pi_cash_entry.thread_order_entry_uuid,
			pi_cash_quantity: pi_cash_entry.pi_cash_quantity,
			created_at: pi_cash_entry.created_at,
			updated_at: pi_cash_entry.updated_at,
			remarks: pi_cash_entry.remarks,
		})
		.from(pi_cash_entry)
		.where(eq(pi_cash_entry.uuid, req.params.uuid));

	try {
		const data = await pi_entryPromise;
		const toast = {
			status: 200,
			type: 'select',
			message: 'pi_cash_entry',
		};

		return res.status(200).json({ toast, data: data[0] });
	} catch (error) {
		await handleError({ error, res });
	}
}

export async function selectPiEntryByPiUuid(req, res, next) {
	if (!(await validateRequest(req, next))) return;

	try {
		const query = sql`
				SELECT
	                pe.uuid as uuid,
                    pe.pi_cash_uuid as pi_cash_uuid,
					pe.pi_cash_quantity as pi_cash_quantity,
					pe.created_at as created_at,
	                pe.updated_at as updated_at,
					CASE WHEN pe.thread_order_entry_uuid IS NOT NULL THEN true ELSE false END as is_thread_order,
					sfg.uuid as sfg_uuid,
					vodf.order_info_uuid as order_info_uuid,
					vodf.order_description_uuid as order_description_uuid,
					vodf.order_number as order_number,
					vodf.buyer_name as buyer_name,
					oe.style as style,
					oe.color as color,
					oe.quantity as quantity,
					vodf.item_description as item_description,
					oe.size as size,
					oe.quantity as max_quantity,
					oe.party_price as unit_price,
					sfg.pi as given_pi_cash_quantity,
					(pe.pi_cash_quantity * oe.party_price) as value,
					(oe.quantity - sfg.pi) as balance_quantity,
					pe.thread_order_entry_uuid as thread_order_entry_uuid,
					concat('TO', to_char(toi.created_at, 'YY'), '-', LPAD(toi.id::text, 4, '0')) as thread_order_number,
					toe.color as toe_color,
					toe.style as toe_style,
					toe.count_length_uuid as count_length_uuid,
					CONCAT(count_length.count,' ', count_length.length) as count_length_name,
					toe.pi as given_pi_cash_quantity_thread,
					(pe.pi_cash_quantity * toe.party_price) as value_thread,
					(oe.quantity - toe.pi) as balance_quantity_thread,
					toe.quantity as thread_max_quantity,
					CASE WHEN pe.uuid IS NOT NULL THEN true ELSE false END as is_checked
	            FROM
					zipper.sfg sfg
	                LEFT JOIN zipper.order_entry oe ON sfg.order_entry_uuid = oe.uuid
	                LEFT JOIN zipper.v_order_details_full vodf ON oe.order_description_uuid = vodf.order_description_uuid
					LEFT JOIN commercial.pi_cash_entry pe ON pe.sfg_uuid = sfg.uuid
					LEFT JOIN thread.order_entry toe ON pe.thread_order_entry_uuid = toe.uuid
					LEFT JOIN thread.order_info toi ON vodf.order_info_uuid = toi.uuid
					LEFT JOIN thread.count_length count_length ON toe.count_length_uuid = count_length.uuid
				WHERE 
					pe.pi_cash_uuid = ${req.params.pi_cash_uuid}
				ORDER BY
	                vodf.order_number ASC,
					vodf.item_description ASC,
					oe.style ASC,
					oe.color ASC,
					oe.size ASC `;

		const pi_entryPromise = db.execute(query);

		const data = await pi_entryPromise;

		// fg_uuid is null then pass thread_order_entry array
		const thread_order_entry = data?.rows.filter(
			(row) => row.sfg_uuid === null
		);

		// fg_uuid is not null then pass zipper_order_entry array
		const zipper_order_entry = data?.rows.filter(
			(row) => row.sfg_uuid !== null
		);

		const toast = {
			status: 200,
			type: 'select',
			message: 'pi_cash_entry By Pi Cash Uuid',
		};

		return res.status(200).json({ toast, data: data?.rows });
	} catch (error) {
		await handleError({ error, res });
	}
}

export async function selectPiEntryByOrderInfoUuid(req, res, next) {
	if (!(await validateRequest(req, next))) return;

	const query = sql`
        SELECT
            sfg.uuid as uuid,
            sfg.uuid as sfg_uuid,
            vod.order_info_uuid,
            vod.order_number as order_number,
            vod.item_description as item_description,
            oe.style as style,
            oe.color as color,
            oe.size as size,
            oe.quantity as quantity,
            sfg.pi as given_pi_cash_quantity,
            (oe.quantity - sfg.pi) as max_quantity,
            (oe.quantity - sfg.pi) as pi_cash_quantity,
            (oe.quantity - sfg.pi) as balance_quantity,
            CASE WHEN pe.uuid IS NOT NULL THEN true ELSE false END as is_checked,
			false as is_thread_order
        FROM
            zipper.sfg sfg
            LEFT JOIN zipper.order_entry oe ON sfg.order_entry_uuid = oe.uuid
            LEFT JOIN zipper.v_order_details vod ON oe.order_description_uuid = vod.order_description_uuid
			LEFT JOIN commercial.pi_cash_entry pe ON pe.sfg_uuid = sfg.uuid
        WHERE
            vod.order_info_uuid = ${req.params.order_info_uuid} AND (oe.quantity - sfg.pi) > 0
        ORDER BY 
            vod.order_number ASC,
            vod.item_description ASC, 
            oe.style ASC, 
            oe.color ASC, 
            oe.size ASC
    `;

	const pi_entryPromise = db.execute(query);

	try {
		const data = await pi_entryPromise;
		const toast = {
			status: 200,
			type: 'select',
			message: 'pi_cash_entry By Order Info Uuid',
		};

		return res.status(200).json({ toast, data: data?.rows });
	} catch (error) {
		await handleError({ error, res });
	}
}

export async function selectPiEntryByThreadOrderInfoUuid(req, res, next) {
	if (!(await validateRequest(req, next))) return;

	const query = sql`
        SELECT
            toe.uuid as uuid,
            toe.uuid as thread_order_entry_uuid,
            toi.uuid as order_info_uuid,
            CONCAT('TO', to_char(toi.created_at, 'YY'), '-', LPAD(toi.id::text, 4, '0')) as order_number,
            toe.style as style,
            toe.color as color,
            toe.quantity as quantity,
            toe.pi as given_pi_cash_quantity,
            (toe.quantity - toe.pi) as max_quantity,
            (toe.quantity - toe.pi) as pi_cash_quantity,
            (toe.quantity - toe.pi) as balance_quantity,
            CASE WHEN pe.uuid IS NOT NULL THEN true ELSE false END as is_checked,
			true as is_thread_order
        FROM
            thread.order_entry toe
            LEFT JOIN thread.order_info toi ON toe.order_info_uuid = toi.uuid
			LEFT JOIN commercial.pi_cash_entry pe ON pe.thread_order_entry_uuid = toe.uuid
        WHERE
            toe.order_info_uuid = ${req.params.order_info_uuid} AND (toe.quantity - toe.pi) > 0
        ORDER BY 
            toi.id ASC,
            toe.style ASC, 
            toe.color ASC
    `;

	const pi_entryPromise = db.execute(query);

	try {
		const data = await pi_entryPromise;
		const toast = {
			status: 200,
			type: 'select',
			message: 'pi_cash_entry By thread Order Info Uuid',
		};

		return res.status(200).json({ toast, data: data?.rows });
	} catch (error) {
		await handleError({ error, res });
	}
}

export async function selectPiEntryByPiDetailsByOrderInfoUuids(req, res, next) {
	try {
		const api = await createApi(req);
		let { order_info_uuids, party_uuid, marketing_uuid } = req?.params;

		if (order_info_uuids === 'null') {
			return res.status(400).json({ error: 'Order Number is required' });
		}

		order_info_uuids = order_info_uuids
			.split(',')
			.map(String)
			.map((String) => [String]);

		const fetchData = async (endpoint, data) => {
			console.log(`${endpoint}/${data}`, 'endpoint - data');

			try {
				const response = await api.get(`${endpoint}/${data}`);
				console.log(response.data, 'response data'); // Log the response data
				return response.data; // Ensure to return the data from the response
			} catch (error) {
				console.error(error);
				return null; // Return null or handle the error as needed
			}
		};

		const results = await Promise.all(
			order_info_uuids.flat().map((uuid) => {
				return Promise.all([
					fetchData('/commercial/pi-cash-entry/details/by', uuid),
					// fetchData(
					// 	'/commercial/pi-cash-entry/thread-details/by',
					// 	uuid
					// ),
				]);
			})
		);

		// Flatten the results array
		const flattenedResults = results;

		// Extract pi_cash_entry and pi_cash_entry_thread from flattenedResults
		const pi_cash_entry = flattenedResults.map((result) => result[0]);
		// const pi_cash_entry_thread = flattenedResults.map(
		// 	(result) => result[1]
		// );

		console.log(pi_cash_entry, 'pi_cash_entry');
		// console.log(pi_cash_entry_thread, 'pi_cash_entry_thread');

		// Check if both pi_cash_entry and pi_cash_entry_thread are undefined
		// const allUndefined =
		// 	pi_cash_entry.every((entry) => entry === undefined) &&
		// 	pi_cash_entry_thread.every((entry) => entry === undefined);

		// if (allUndefined) {
		// 	throw new Error(
		// 		'Both pi_cash_entry and pi_cash_entry_thread are undefined'
		// 	);
		// }

		order_info_uuids = order_info_uuids.flat();

		const response = {
			party_uuid,
			marketing_uuid,
			order_info_uuids,
			pi_cash_entry: pi_cash_entry?.reduce((acc, result) => {
				return [...acc, ...(result?.data || [])];
			}, []),
			// pi_cash_entry_thread: pi_cash_entry_thread?.reduce(
			// 	(acc, result) => {
			// 		return [...acc, ...(result?.data || [])];
			// 	},
			// 	[]
			// ),
			// Other response properties
		};

		const toast = {
			status: 200,
			type: 'select',
			msg: 'Pi Details By Order Info Uuids',
		};

		res.status(200).json({ toast, data: response });
	} catch (error) {
		return res.status(500).json(error);
	}
}

export async function selectPiEntryByPiDetailsByThreadOrderInfoUuids(
	req,
	res,
	next
) {
	try {
		const api = await createApi(req);
		let { order_info_uuids, party_uuid, marketing_uuid } = req?.params;

		if (order_info_uuids === 'null') {
			return res.status(400).json({ error: 'Order Number is required' });
		}

		order_info_uuids = order_info_uuids
			.split(',')
			.map(String)
			.map((String) => [String]);

		const fetchDataThread = async (endpoint) =>
			await api.get(
				`/commercial/pi-cash-entry/thread-details/by/${endpoint}`
			);

		const result2 = await Promise.all(
			order_info_uuids.flat().map((uuid) => fetchDataThread(uuid))
		);

		order_info_uuids = order_info_uuids.flat();

		const response = {
			party_uuid,
			marketing_uuid,
			order_info_uuids,
			pi_cash_entry_thread: result2?.reduce((acc, result) => {
				return [...acc, ...result?.data?.data];
			}, []),
		};

		console.log(response, 'response - thread_order');

		const toast = {
			status: 200,
			type: 'select',
			msg: 'Pi Details By Order Info Uuids',
		};

		res.status(200).json({ toast, data: response });
	} catch (error) {
		return res.status(500).json(error);
	}
}
