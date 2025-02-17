import { and, eq, min, sql, sum } from 'drizzle-orm';
import { alias } from 'drizzle-orm/pg-core';
import {
	handleError,
	handleResponse,
	validateRequest,
} from '../../../util/index.js';
import db from '../../index.js';
import { decimalToNumber } from '../../variables.js';

import * as commercialSchema from '../../commercial/schema.js';
import * as deliverySchema from '../../delivery/schema.js';
import * as hrSchema from '../../hr/schema.js';
import * as labDipSchema from '../../lab_dip/schema.js';
import * as materialSchema from '../../material/schema.js';
import * as publicSchema from '../../public/schema.js';
import * as purchaseSchema from '../../purchase/schema.js';
import * as sliderSchema from '../../slider/schema.js';
import * as threadSchema from '../../thread/schema.js';
import * as zipperSchema from '../../zipper/schema.js';

// * Aliases * //
const itemProperties = alias(publicSchema.properties, 'itemProperties');
const zipperProperties = alias(publicSchema.properties, 'zipperProperties');
const endTypeProperties = alias(publicSchema.properties, 'endTypeProperties');
const pullerTypeProperties = alias(
	publicSchema.properties,
	'pullerTypeProperties'
);

//* public
export async function selectMachine(req, res, next) {
	const machinePromise = db
		.select({
			value: publicSchema.machine.uuid,
			label: publicSchema.machine.name,
			max_capacity: decimalToNumber(publicSchema.machine.max_capacity),
			min_capacity: decimalToNumber(publicSchema.machine.min_capacity),
		})
		.from(publicSchema.machine);

	const toast = {
		status: 200,
		type: 'select_all',
		message: 'Machine list',
	};
	handleResponse({
		promise: machinePromise,
		res,
		next,
		...toast,
	});
}

export async function selectParty(req, res, next) {
	const partyPromise = db
		.select({
			value: publicSchema.party.uuid,
			label: publicSchema.party.name,
		})
		.from(publicSchema.party);

	const toast = {
		status: 200,
		type: 'select_all',
		message: 'Party list',
	};
	handleResponse({
		promise: partyPromise,
		res,
		next,
		...toast,
	});
}

export async function selectMarketingUser(req, res, next) {
	const userPromise = db
		.select({
			value: hrSchema.users.uuid,
			label: sql`concat(users.name,
				' - ',
				designation.designation,
				' - ',
				department.department)`,
		})
		.from(hrSchema.users)
		.leftJoin(
			hrSchema.designation,
			eq(hrSchema.users.designation_uuid, hrSchema.designation.uuid)
		)
		.leftJoin(
			hrSchema.department,
			eq(hrSchema.users.department_uuid, hrSchema.department.uuid)
		)
		.where(eq(hrSchema.department.department, 'Sales And Marketing'));

	const toast = {
		status: 200,
		type: 'select',
		message: 'marketing user',
	};

	handleResponse({ promise: userPromise, res, next, ...toast });
}

export async function selectBuyer(req, res, next) {
	const buyerPromise = db
		.select({
			value: publicSchema.buyer.uuid,
			label: publicSchema.buyer.name,
		})
		.from(publicSchema.buyer);

	const toast = {
		status: 200,
		type: 'select_all',
		message: 'Buyer list',
	};
	handleResponse({
		promise: buyerPromise,
		res,
		next,
		...toast,
	});
}

export function selectSpecificMerchandiser(req, res, next) {
	if (!validateRequest(req, next)) return;

	const merchandiserPromise = db
		.select({
			value: publicSchema.merchandiser.uuid,
			label: publicSchema.merchandiser.name,
		})
		.from(publicSchema.merchandiser)
		.leftJoin(
			publicSchema.party,
			eq(publicSchema.merchandiser.party_uuid, publicSchema.party.uuid)
		)
		.where(eq(publicSchema.party.uuid, req.params.party_uuid));

	const toast = {
		status: 200,
		type: 'select',
		message: 'Merchandiser',
	};

	handleResponse({
		promise: merchandiserPromise,
		res,
		next,
		...toast,
	});
}

export function selectSpecificFactory(req, res, next) {
	if (!validateRequest(req, next)) return;

	const factoryPromise = db
		.select({
			value: publicSchema.factory.uuid,
			label: publicSchema.factory.name,
		})
		.from(publicSchema.factory)
		.leftJoin(
			publicSchema.party,
			eq(publicSchema.factory.party_uuid, publicSchema.party.uuid)
		)
		.where(eq(publicSchema.party.uuid, req.params.party_uuid));

	const toast = {
		status: 200,
		type: 'select',
		message: 'Factory',
	};

	handleResponse({
		promise: factoryPromise,
		res,
		next,
		...toast,
	});
}

export function selectMarketing(req, res, next) {
	const marketingPromise = db
		.select({
			value: publicSchema.marketing.uuid,
			label: publicSchema.marketing.name,
		})
		.from(publicSchema.marketing);

	const toast = {
		status: 200,
		type: 'select_all',
		message: 'Marketing list',
	};
	handleResponse({
		promise: marketingPromise,
		res,
		next,
		...toast,
	});
}

export function selectOrderProperties(req, res, next) {
	if (!validateRequest(req, next)) return;

	const orderPropertiesPromise = db
		.select({
			value: publicSchema.properties.uuid,
			label: publicSchema.properties.name,
		})
		.from(publicSchema.properties)
		.where(eq(publicSchema.properties.type, req.params.type_name));

	const toast = {
		status: 200,
		type: 'select_all',
		message: 'Order Properties list',
	};
	handleResponse({
		promise: orderPropertiesPromise,
		res,
		next,
		...toast,
	});
}

// zipper
export function selectOrderInfo(req, res, next) {
	if (!validateRequest(req, next)) return;

	const orderInfoPromise = db
		.select({
			value: zipperSchema.order_info.uuid,
			label: sql`CONCAT('Z', to_char(order_info.created_at, 'YY'), '-', LPAD(order_info.id::text, 4, '0'))`,
		})
		.from(zipperSchema.order_info);

	const toast = {
		status: 200,
		type: 'select_all',
		message: 'Order Info list',
	};

	handleResponse({
		promise: orderInfoPromise,
		res,
		next,
		...toast,
	});
}

export async function selectOrderZipperThread(req, res, next) {
	if (!validateRequest(req, next)) return;

	const query = sql`SELECT
							oz.uuid AS value,
							CONCAT('Z', to_char(oz.created_at, 'YY'), '-', LPAD(oz.id::text, 4, '0')) as label
						FROM
							zipper.order_info oz
						UNION 
						SELECT
							ot.uuid AS value,
							CONCAT('TO', to_char(ot.created_at, 'YY'), '-', LPAD(ot.id::text, 4, '0')) as label
						FROM
							thread.order_info ot`;

	const orderZipperThreadPromise = db.execute(query);

	try {
		const data = await orderZipperThreadPromise;

		const toast = {
			status: 200,
			type: 'select_all',
			message: 'Order Zipper Thread list',
		};

		res.status(200).json({ toast, data: data?.rows });
	} catch (error) {
		await handleError({ error, res });
	}
}

export async function selectOrderInfoToGetOrderDescription(req, res, next) {
	if (!validateRequest(req, next)) return;

	const { order_number } = req.params;

	const query = sql`SELECT * FROM zipper.v_order_details WHERE v_order_details.order_number = ${order_number}`;

	const orderInfoPromise = db.execute(query);

	try {
		const data = await orderInfoPromise;

		const toast = {
			status: 200,
			type: 'select_all',
			message: 'Order Info list',
		};

		res.status(200).json({ toast, data: data?.rows });
	} catch (error) {
		await handleError({ error, res });
	}
}

export async function selectOrderEntry(req, res, next) {
	const query = sql`SELECT
					oe.uuid AS value,
					CONCAT(vodf.order_number, ' ⇾ ', vodf.item_description, ' ⇾ ', oe.style, '/', oe.color, '/', 
					CASE 
					WHEN vodf.is_inch = 1 THEN CAST(CAST(oe.size AS NUMERIC) * 2.54 AS TEXT)
					ELSE oe.size END
					) AS label,
					oe.quantity::float8 AS quantity,
					oe.quantity - (
						COALESCE(sfg.coloring_prod, 0) + COALESCE(sfg.finishing_prod, 0)
					)::float8 AS can_trf_quantity
				FROM
					zipper.order_entry oe
					LEFT JOIN zipper.v_order_details_full vodf ON oe.order_description_uuid = vodf.order_description_uuid
					LEFT JOIN zipper.sfg sfg ON sfg.order_entry_uuid = oe.uuid
				`;
	// WHERE oe.swatch_status_enum = 'approved' For development purpose, removed

	const orderEntryPromise = db.execute(query);

	try {
		const data = await orderEntryPromise;

		const toast = {
			status: 200,
			type: 'select_all',
			message: 'Order Entry list',
		};

		res.status(200).json({ toast, data: data?.rows });
	} catch (error) {
		await handleError({ error, res });
	}
}

export async function selectOrderDescription(req, res, next) {
	const { item, tape_received } = req.query;

	const query = sql`
				SELECT
					vodf.order_description_uuid AS value,
					CONCAT(vodf.order_number, ' ⇾ ', vodf.item_description, ' ⇾ ', vodf.tape_received) AS label,
					vodf.item_name,
					vodf.tape_received::float8,
					vodf.tape_transferred::float8,
					totals_of_oe.total_size::float8,
					totals_of_oe.total_quantity::float8,
					tcr.top::float8,
					tcr.bottom::float8,
					tape_coil.dyed_per_kg_meter::float8,
					coalesce(batch_stock.stock,0)::float8 as stock
				FROM
					zipper.v_order_details_full vodf
				LEFT JOIN 
					(
						SELECT oe.order_description_uuid, 
						SUM(CASE 
							WHEN vodf.is_inch = 1 THEN CAST(CAST(oe.size AS NUMERIC) * 2.54 AS TEXT)::numeric
							ELSE oe.size::numeric
						END * oe.quantity::numeric) as total_size, 
						SUM(oe.quantity::numeric) as total_quantity
						FROM zipper.order_entry oe 
						LEFT JOIN zipper.v_order_details_full vodf ON oe.order_description_uuid = vodf.order_description_uuid
				        group by oe.order_description_uuid
					) AS totals_of_oe ON totals_of_oe.order_description_uuid = vodf.order_description_uuid 
				LEFT JOIN zipper.tape_coil_required tcr ON
					vodf.item = tcr.item_uuid  
					AND vodf.zipper_number = tcr.zipper_number_uuid 
					AND vodf.end_type = tcr.end_type_uuid 
					AND (
						lower(vodf.item_name) != 'nylon' 
						OR vodf.nylon_stopper = tcr.nylon_stopper_uuid
					)
				LEFT JOIN zipper.tape_coil ON vodf.tape_coil_uuid = tape_coil.uuid
				LEFT JOIN (
					SELECT oe.order_description_uuid, SUM(be.production_quantity_in_kg) as stock
					FROM zipper.order_entry oe
						LEFT JOIN zipper.sfg ON oe.uuid = sfg.order_entry_uuid
						LEFT JOIN zipper.batch_entry be ON be.sfg_uuid = sfg.uuid
						LEFT JOIN zipper.batch b ON b.uuid = be.batch_uuid
					WHERE b.received = 1
					GROUP BY oe.order_description_uuid
				) batch_stock ON vodf.order_description_uuid = batch_stock.order_description_uuid
				WHERE 
					vodf.item_description != '---' AND vodf.item_description != '' AND tape_coil.dyed_per_kg_meter IS NOT NULL
				`;

	if (item == 'nylon') {
		query.append(sql` AND LOWER(vodf.item_name) = 'nylon'`);
	} else if (item == 'without-nylon') {
		query.append(sql` AND LOWER(vodf.item_name) != 'nylon'`);
	}

	if (tape_received == 'true') {
		query.append(sql` AND vodf.tape_received > 0`);
	}

	const orderEntryPromise = db.execute(query);

	try {
		const data = await orderEntryPromise;

		const toast = {
			status: 200,
			type: 'select_all',
			message: 'Order Description list',
		};

		res.status(200).json({ toast, data: data?.rows });
	} catch (error) {
		await handleError({ error, res });
	}
}

// export async function selectOrderDescriptionByItemNameAndZipperNumber(
// 	req,
// 	res,
// 	next
// ) {
// 	const { item_name, zipper_number } = req.params;

// 	const query = sql`SELECT
// 					vodf.order_description_uuid AS value,
// 					CONCAT(vodf.order_number, ' ⇾ ', vodf.item_description, ' ⇾ ', vodf.tape_received) AS label

// 				FROM
// 					zipper.v_order_details_full vodf
// 				WHERE
// 					vodf.item_name = ${item_name} AND
// 					vodf.zipper_number_name = ${zipper_number}
// 				`;

// 	const orderEntryPromise = db.execute(query);

// 	try {
// 		const data = await orderEntryPromise;

// 		const toast = {
// 			status: 200,
// 			type: 'select_all',
// 			message: 'Order Description list',
// 		};

// 		res.status(200).json({ toast, data: data?.rows });
// 	} catch (error) {
// 		await handleError({ error, res });
// 	}
// }

export async function selectOrderDescriptionByCoilUuid(req, res, next) {
	const { coil_uuid } = req.params;
	const tapeCOilQuery = sql`
			SELECT
				item_uuid,
				zipper_number_uuid
			FROM
				zipper.tape_coil
			WHERE
				uuid = ${coil_uuid}
	`;
	try {
		const tapeCoilData = await db.execute(tapeCOilQuery);
		const item_uuid = tapeCoilData.rows[0].item_uuid;
		const zipper_number_uuid = tapeCoilData.rows[0].zipper_number_uuid;

		const query = sql`
			SELECT
				vodf.order_description_uuid AS value,
				CONCAT(vodf.order_number, ' ⇾ ', vodf.item_description, ' ⇾ ', vodf.tape_received) AS label,
				totals_of_oe.total_size::float8,
				totals_of_oe.total_quantity::float8,
				tcr.top::float8,
				tcr.bottom::float8,
				vodf.tape_received::float8,
				vodf.tape_transferred::float8
			FROM
				zipper.v_order_details_full vodf
			LEFT JOIN (
				SELECT oe.order_description_uuid, 
					SUM(
					CASE 
						WHEN vodf.is_inch = 1 THEN CAST(CAST(oe.size AS NUMERIC) * 2.54 AS TEXT)::numeric
						ELSE oe.size::numeric
					END * oe.quantity::numeric) as total_size, 
					SUM(oe.quantity::numeric) as total_quantity
				FROM zipper.order_entry oe
				LEFT JOIN zipper.v_order_details_full vodf ON oe.order_description_uuid = vodf.order_description_uuid
				GROUP BY oe.order_description_uuid
			) totals_of_oe ON vodf.order_description_uuid = totals_of_oe.order_description_uuid
			LEFT JOIN zipper.tape_coil_required tcr ON 
				vodf.item = tcr.item_uuid  
				AND vodf.zipper_number = tcr.zipper_number_uuid 
				AND vodf.end_type = tcr.end_type_uuid 
				AND (
					lower(vodf.item_name) != 'nylon' 
					OR vodf.nylon_stopper = tcr.nylon_stopper_uuid
				)
			LEFT JOIN 
				public.properties item_properties ON vodf.item = item_properties.uuid
			WHERE
				(vodf.tape_coil_uuid = ${coil_uuid} OR (vodf.item = ${item_uuid} AND vodf.zipper_number = ${zipper_number_uuid} AND vodf.tape_coil_uuid IS NULL)) AND vodf.order_description_uuid IS NOT NULL
		`;

		const orderEntryPromise = db.execute(query);

		const data = await orderEntryPromise;

		const toast = {
			status: 200,
			type: 'select_all',
			message: 'Order Description list',
		};

		res.status(200).json({ toast, data: data?.rows });
	} catch (error) {
		await handleError({ error, res });
	}
}

export async function selectOrderNumberForPi(req, res, next) {
	const is_cash = req.query.is_cash;
	const pi_uuid = req.query.pi_uuid;

	let query;

	if (
		is_cash == null ||
		is_cash == undefined ||
		is_cash == '' ||
		is_cash == 'true'
	) {
		query = sql`
			SELECT
				DISTINCT vod.order_info_uuid AS value,
				vod.order_number AS label
			FROM
				zipper.v_order_details vod
				LEFT JOIN zipper.order_info oi ON vod.order_info_uuid = oi.uuid
			WHERE
				vod.is_cash = 1 AND
				vod.marketing_uuid = ${req.params.marketing_uuid} AND
				oi.party_uuid = ${req.params.party_uuid}
			ORDER BY
				vod.order_number ASC
`;
	} else {
		query = sql`
			SELECT
				DISTINCT vod.order_info_uuid AS value,
				vod.order_number AS label
			FROM
				zipper.v_order_details vod
				LEFT JOIN zipper.order_info oi ON vod.order_info_uuid = oi.uuid
			WHERE
				vod.is_cash = 0 AND
				vod.marketing_uuid = ${req.params.marketing_uuid} AND
				oi.party_uuid = ${req.params.party_uuid}
				${pi_uuid ? sql`AND vod.order_info_uuid IN (SELECT json_array_elements_text(order_info_uuids::json) FROM commercial.pi_cash WHERE uuid = ${pi_uuid})` : sql``}
			ORDER BY
				vod.order_number ASC`;
	}

	const orderNumberPromise = db.execute(query);

	try {
		const data = await orderNumberPromise;

		const toast = {
			status: 200,
			type: 'select',
			message: 'Order Number of a marketing and party',
		};

		res.status(200).json({ toast, data: data?.rows });
	} catch (error) {
		await handleError({ error, res });
	}
}

// purchase
export async function selectVendor(req, res, next) {
	const vendorPromise = db
		.select({
			value: purchaseSchema.vendor.uuid,
			label: purchaseSchema.vendor.name,
		})
		.from(purchaseSchema.vendor);

	try {
		const data = await vendorPromise;

		const toast = {
			status: 200,
			type: 'select_all',
			message: 'Vendor list',
		};

		res.status(200).json({ toast, data: data });
	} catch (error) {
		await handleError({ error, res });
	}
}

// material
export async function selectMaterialSection(req, res, next) {
	const sectionPromise = db
		.select({
			value: materialSchema.section.uuid,
			label: materialSchema.section.name,
		})
		.from(materialSchema.section);

	const toast = {
		status: 200,
		type: 'select_all',
		message: 'Section list',
	};
	handleResponse({
		promise: sectionPromise,
		res,
		next,
		...toast,
	});
}

export async function selectMaterialType(req, res, next) {
	const typePromise = db
		.select({
			value: materialSchema.type.uuid,
			label: materialSchema.type.name,
		})
		.from(materialSchema.type);

	const toast = {
		status: 200,
		type: 'select_all',
		message: 'Type list',
	};
	handleResponse({
		promise: typePromise,
		res,
		next,
		...toast,
	});
}

export async function selectMaterial(req, res, next) {
	const type = req.query.type;
	const infoPromise = db
		.select({
			value: materialSchema.info.uuid,
			label: materialSchema.info.name,
			unit: materialSchema.info.unit,
			stock: decimalToNumber(materialSchema.stock.stock),
		})
		.from(materialSchema.info)
		.leftJoin(
			materialSchema.stock,
			eq(materialSchema.info.uuid, materialSchema.stock.material_uuid)
		)
		.leftJoin(
			materialSchema.type,
			eq(materialSchema.info.type_uuid, materialSchema.type.uuid)
		)
		.where(
			type
				? eq(sql`lower(material.type.name)`, sql`lower(${type})`)
				: null
		);

	const toast = {
		status: 200,
		type: 'select_all',
		message: 'Material list',
	};
	handleResponse({
		promise: infoPromise,
		res,
		next,
		...toast,
	});
}

// Commercial

export async function selectBank(req, res, next) {
	const bankPromise = db
		.select({
			value: commercialSchema.bank.uuid,
			label: commercialSchema.bank.name,
		})
		.from(commercialSchema.bank);

	const toast = {
		status: 200,
		type: 'select_all',
		message: 'Bank list',
	};
	handleResponse({
		promise: bankPromise,
		res,
		next,
		...toast,
	});
}

export async function selectLCByPartyUuid(req, res, next) {
	const lcPromise = db
		.select({
			value: commercialSchema.lc.uuid,
			label: commercialSchema.lc.lc_number,
		})
		.from(commercialSchema.lc)
		.where(eq(commercialSchema.lc.party_uuid, req.params.party_uuid));

	const toast = {
		status: 200,
		type: 'select',
		message: 'LC list of a party',
	};
	handleResponse({
		promise: lcPromise,
		res,
		next,
		...toast,
	});
}

export async function selectPi(req, res, next) {
	const { is_update } = req.query;

	const query = sql`
	SELECT
		DISTINCT pi_cash.uuid AS value,
		CONCAT('PI', TO_CHAR(pi_cash.created_at, 'YY'), '-', LPAD(pi_cash.id::text, 4, '0')) AS label,
		bank.name AS pi_bank,
		SUM(pi_cash_entry.pi_cash_quantity * zipper.order_entry.party_price)::float8 AS pi_value,
		ARRAY_AGG(DISTINCT v_order_details.order_number) AS order_numbers,
		v_order_details.marketing_name
	FROM
		commercial.pi_cash
	LEFT JOIN
		commercial.bank ON pi_cash.bank_uuid = bank.uuid
	LEFT JOIN
		commercial.pi_cash_entry ON pi_cash.uuid = pi_cash_entry.pi_cash_uuid
	LEFT JOIN
		zipper.sfg ON pi_cash_entry.sfg_uuid = sfg.uuid
	LEFT JOIN
		zipper.order_entry ON order_entry.uuid = sfg.order_entry_uuid
	LEFT JOIN
		zipper.v_order_details ON v_order_details.order_description_uuid = order_entry.order_description_uuid
	WHERE
		pi_cash.is_pi = 1 
		${is_update == 'true' ? sql`` : sql`AND lc_uuid IS NULL`}
	GROUP BY
		pi_cash.uuid,
		bank.name,
		v_order_details.party_name,
		v_order_details.marketing_name;
	`;

	const piPromise = db.execute(query);

	try {
		const data = await piPromise;

		const toast = {
			status: 200,
			type: 'select_all',
			message: 'PI list',
		};

		res.status(200).json({ toast, data: data?.rows });
	} catch (error) {
		await handleError({ error, res });
	}
}
// * HR * //
//* HR Department *//
export async function selectDepartment(req, res, next) {
	const departmentPromise = db
		.select({
			value: hrSchema.department.uuid,
			label: hrSchema.department.department,
		})
		.from(hrSchema.department);

	const toast = {
		status: 200,
		type: 'select_all',
		message: 'Department list',
	};
	handleResponse({
		promise: departmentPromise,
		res,
		next,
		...toast,
	});
}
//* HR User *//
export async function selectHrUser(req, res, next) {
	const { designation } = req.query;

	const userPromise = db
		.select({
			value: hrSchema.users.uuid,
			label: hrSchema.users.name,
			designation: hrSchema.designation.designation,
		})
		.from(hrSchema.users)
		.leftJoin(
			hrSchema.designation,
			eq(hrSchema.users.designation_uuid, hrSchema.designation.uuid)
		)
		.where(
			designation
				? eq(sql`lower(designation.designation)`, designation)
				: null
		);

	try {
		const data = await userPromise;

		const toast = {
			status: 200,
			type: 'select_all',
			message: 'User list',
		};

		res.status(200).json({ toast, data: data });
	} catch (error) {
		await handleError({ error, res });
	}
}

export async function selectDesignation(req, res, next) {
	const Designation = db
		.select({
			value: hrSchema.designation.uuid,
			label: hrSchema.designation.designation,
		})
		.from(hrSchema.designation);

	const toast = {
		status: 200,
		type: 'select_all',
		message: 'Designation list',
	};
	handleResponse({
		promise: Designation,
		res,
		next,
		...toast,
	});
}

// * Lab Dip * //
export async function selectLabDipRecipe(req, res, next) {
	const { order_info_uuid, bleaching, info_uuid } = req.query;

	const recipePromise = db
		.select({
			value: labDipSchema.recipe.uuid,
			label: sql`concat('LDR', to_char(recipe.created_at, 'YY'), '-', LPAD(recipe.id::text, 4, '0'), ' - ', recipe.name )`,
			approved: labDipSchema.recipe.approved,
			status: labDipSchema.recipe.status,
			info: labDipSchema.recipe.lab_dip_info_uuid,
		})
		.from(labDipSchema.recipe)
		.leftJoin(
			labDipSchema.info,
			eq(labDipSchema.recipe.lab_dip_info_uuid, labDipSchema.info.uuid)
		)
		.where(
			order_info_uuid
				? and(
						eq(labDipSchema.info.order_info_uuid, order_info_uuid),
						eq(labDipSchema.recipe.approved, 1),
						bleaching
							? eq(labDipSchema.recipe.bleaching, bleaching)
							: null
					)
				: info_uuid
					? sql`${labDipSchema.recipe.lab_dip_info_uuid} is null`
					: null
		);

	const toast = {
		status: 200,
		type: 'select_all',
		message: 'Lab Dip Recipe list',
	};
	handleResponse({
		promise: recipePromise,
		res,
		next,
		...toast,
	});
}

export async function selectLabDipShadeRecipe(req, res, next) {
	const { thread_order_info_uuid, bleaching } = req.query;
	const query = sql`
	SELECT
		recipe.uuid AS value,
		recipe.name AS label
	FROM
		lab_dip.recipe
	LEFT JOIN
		lab_dip.info ON recipe.lab_dip_info_uuid = lab_dip.info.uuid
	WHERE
	  ${thread_order_info_uuid ? sql`lab_dip.info.thread_order_info_uuid = ${thread_order_info_uuid} AND lab_dip.recipe.approved = 1 ` : sql`1=1`}
	  AND
	  ${bleaching ? sql` recipe.bleaching = ${bleaching}` : sql`1=1`}
	`;

	const RecipePromise = db.execute(query);

	try {
		const data = await RecipePromise;

		const toast = {
			status: 200,
			type: 'select_all',
			message: 'Lab Dip Recipe list',
		};

		res.status(200).json({ toast, data: data?.rows });
	} catch (error) {
		await handleError({ error, res });
	}
}

export async function selectLabDipInfo(req, res, next) {
	const InfoPromise = db
		.select({
			value: labDipSchema.info.uuid,
			label: sql`concat('LDI', to_char(info.created_at, 'YY'), '-', LPAD(info.id::text, 4, '0'))`,
		})
		.from(labDipSchema.info);

	const toast = {
		status: 200,
		type: 'select_all',
		message: 'Info list',
	};

	handleResponse({
		promise: InfoPromise,
		res,
		next,
		...toast,
	});
}

// * Slider * //
export async function selectNameFromDieCastingStock(req, res, next) {
	const query = sql`
	SELECT
		die_casting.uuid AS value,
		concat(
			die_casting.name, ' --> ',
			itemProperties.short_name, ' - ',
			zipperProperties.short_name, ' - ',
			endTypeProperties.short_name, ' - ',
			pullerTypeProperties.short_name
		) AS label
	FROM
		slider.die_casting
	LEFT JOIN
		public.properties as itemProperties ON die_casting.item = itemProperties.uuid
	LEFT JOIN
		public.properties as zipperProperties ON die_casting.zipper_number = zipperProperties.uuid
	LEFT JOIN
		public.properties as endTypeProperties ON die_casting.end_type = endTypeProperties.uuid
	LEFT JOIN
		public.properties as pullerTypeProperties ON die_casting.puller_type = pullerTypeProperties.uuid;`;

	const namePromise = db.execute(query);

	try {
		const data = await namePromise;

		const toast = {
			status: 200,
			type: 'select_all',
			message: 'Name list from Die Casting',
		};

		res.status(200).json({ toast, data: data?.rows });
	} catch (error) {
		await handleError({ error, res });
	}
}

export async function selectSliderStockWithOrderDescription(req, res, next) {
	const query = sql`
	SELECT
		stock.uuid AS value,
		concat(
			vodf.order_number, ' ⇾ ',
			vodf.item_description
		) AS label
	FROM
		slider.stock
	LEFT JOIN
		zipper.v_order_details_full vodf ON stock.order_description_uuid = vodf.order_description_uuid;
		`;

	const stockPromise = db.execute(query);

	try {
		const data = await stockPromise;

		const toast = {
			status: 200,
			type: 'select_all',
			message: 'Slider Stock list',
		};

		res.status(200).json({ toast, data: data?.rows });
	} catch (error) {
		await handleError({ error, res });
	}
}

// die casting using type

export async function selectDieCastingUsingType(req, res, next) {
	const { type } = req.params;

	const query = sql`
	SELECT
		die_casting.uuid AS value,
		die_casting.name AS label
	FROM
		slider.die_casting
	WHERE
		die_casting.type = ${type};`;

	const namePromise = db.execute(query);

	try {
		const data = await namePromise;

		const toast = {
			status: 200,
			type: 'select_all',
			message: 'Name list from Die Casting',
		};

		res.status(200).json({ toast, data: data?.rows });
	} catch (error) {
		await handleError({ error, res });
	}
}

// * Thread *//

// Order Info

export async function selectThreadOrder(req, res, next) {
	if (!validateRequest(req, next)) return;

	const query = sql`
						SELECT
							ot.uuid AS value,
							CONCAT('TO', to_char(ot.created_at, 'YY'), '-', LPAD(ot.id::text, 4, '0')) as label
						FROM
							thread.order_info ot`;

	const orderThreadPromise = db.execute(query);

	try {
		const data = await orderThreadPromise;

		const toast = {
			status: 200,
			type: 'select_all',
			message: 'Thread list',
		};

		res.status(200).json({ toast, data: data?.rows });
	} catch (error) {
		await handleError({ error, res });
	}
}

export async function selectOrderNumberForPiThread(req, res, next) {
	const { marketing_uuid, party_uuid } = req.params;
	const { is_cash, pi_uuid } = req.query;
	let query;

	if (
		is_cash == null ||
		is_cash == undefined ||
		is_cash == '' ||
		is_cash == 'true'
	) {
		query = sql`
		SELECT
			DISTINCT toi.uuid AS value,
			concat('TO', to_char(toi.created_at, 'YY'), '-', LPAD(toi.id::text, 4, '0')) AS label
		FROM
			thread.order_info toi
		LEFT JOIN
			thread.order_entry toe ON toi.uuid = toe.order_info_uuid
		WHERE
			toi.is_cash = 1 AND
			toi.marketing_uuid = ${marketing_uuid} AND
			toi.party_uuid = ${party_uuid}
	`;
	} else {
		query = sql`
		SELECT
			DISTINCT toi.uuid AS value,
			concat('TO', to_char(toi.created_at, 'YY'), '-', LPAD(toi.id::text, 4, '0')) AS label
		FROM
			thread.order_info toi
		LEFT JOIN
			thread.order_entry toe ON toi.uuid = toe.order_info_uuid
		WHERE
			toi.is_cash = 0 AND
			toi.marketing_uuid = ${marketing_uuid} AND
			toi.party_uuid = ${party_uuid}
		${pi_uuid ? sql`AND toi.uuid IN (SELECT json_array_elements_text(thread_order_info_uuids::json) FROM commercial.pi_cash WHERE uuid = ${pi_uuid})` : sql``}
	`;
	}

	const orderInfoPromise = db.execute(query);

	try {
		const data = await orderInfoPromise;

		const toast = {
			status: 200,
			type: 'select_all',
			message: 'Thread Order Info list',
		};

		res.status(200).json({ toast, data: data.rows });
	} catch (error) {
		await handleError({ error, res });
	}
}

// Count Length

export async function selectCountLength(req, res, next) {
	const query = sql`
	SELECT
		count_length.uuid AS value,
		concat(count_length.count, '/', count_length.length) AS label
	FROM
		thread.count_length;`;

	const countLengthPromise = db.execute(query);

	try {
		const data = await countLengthPromise;

		const toast = {
			status: 200,
			type: 'select_all',
			message: 'Count Length list',
		};

		res.status(200).json({ toast, data: data?.rows });
	} catch (error) {
		await handleError({ error, res });
	}
}

// Batch Id

export async function selectBatchId(req, res, next) {
	const batchIdPromise = db
		.select({
			value: threadSchema.batch.uuid,
			label: sql`concat('TB', to_char(batch.created_at, 'YY'), '-', LPAD(batch.id::text, 4, '0'))`,
		})
		.from(threadSchema.batch);

	const toast = {
		status: 200,
		type: 'select_all',
		message: 'Batch Id list',
	};

	handleResponse({
		promise: batchIdPromise,
		res,
		next,
		...toast,
	});
}

// Dyes Category
export async function selectDyesCategory(req, res, next) {
	const dyesCategoryPromise = db
		.select({
			value: threadSchema.dyes_category.uuid,
			label: sql`concat(dyes_category.name, ' - ', dyes_category.id, ' - ', dyes_category.bleaching)`,
		})
		.from(threadSchema.dyes_category);

	const toast = {
		status: 200,
		type: 'select_all',
		message: 'Dyes Category list',
	};
	handleResponse({
		promise: dyesCategoryPromise,
		res,
		next,
		...toast,
	});
}

// * Delivery * //
// packing list
export async function selectPackingListByOrderInfoUuid(req, res, next) {
	const { order_info_uuid } = req.params;

	const { challan_uuid } = req.query;

	let query = sql`
	SELECT
		pl.uuid AS value,
		concat('PL', to_char(pl.created_at, 'YY'), '-', LPAD(pl.id::text, 4, '0')) AS label
	FROM
		delivery.packing_list pl
	WHERE
		pl.order_info_uuid = ${order_info_uuid} AND (pl.challan_uuid IS NULL`;

	// Conditionally add the challan_uuid part
	if (
		challan_uuid != undefined &&
		challan_uuid != '' &&
		challan_uuid != 'null'
	) {
		query.append(sql` OR pl.challan_uuid = ${challan_uuid}`);
	}
	query.append(sql`);`);

	const packingListPromise = db.execute(query);

	try {
		const data = await packingListPromise;

		const toast = {
			status: 200,
			type: 'select_all',
			message: 'Packing List list',
		};

		res.status(200).json({ toast, data: data?.rows });
	} catch (error) {
		await handleError({ error, res });
	}
}
