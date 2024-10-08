import { desc, eq, sql } from 'drizzle-orm';
import { createApi } from '../../../util/api.js';
import {
	handleError,
	handleResponse,
	validateRequest,
} from '../../../util/index.js';

import * as hrSchema from '../../hr/schema.js';
import db from '../../index.js';
import * as publicSchema from '../../public/schema.js';

import { bank, lc, pi } from '../schema.js';

export async function insert(req, res, next) {
	if (!(await validateRequest(req, next))) return;

	const {
		uuid,
		order_info_uuids,
		marketing_uuid,
		party_uuid,
		merchandiser_uuid,
		factory_uuid,
		bank_uuid,
		validity,
		payment,
		created_by,
		created_at,
		remarks,
	} = req.body;

	const piPromise = db
		.insert(pi)
		.values({
			uuid,
			order_info_uuids,
			marketing_uuid,
			party_uuid,
			merchandiser_uuid,
			factory_uuid,
			bank_uuid,
			validity,
			payment,
			created_by,
			created_at,
			remarks,
		})
		.returning({
			insertedId: sql`concat('PI', to_char(pi.created_at, 'YY'), '-', LPAD(pi.id::text, 4, '0'))`,
		});
	try {
		const data = await piPromise;
		const toast = {
			status: 201,
			type: 'create',
			message: `${data[0].insertedId} created`,
		};

		return await res.status(201).json({ toast, data });
	} catch (error) {
		await handleError({ error, res });
	}
}

export async function update(req, res, next) {
	if (!(await validateRequest(req, next))) return;

	const piPromise = db
		.update(pi)
		.set(req.body)
		.where(eq(pi.uuid, req.params.uuid))
		.returning({
			updatedId: sql`concat('PI', to_char(pi.created_at, 'YY'), '-', LPAD(pi.id::text, 4, '0'))`,
		});

	try {
		const data = await piPromise;
		const toast = {
			status: 201,
			type: 'update',
			message: `updated by ${data[0].updatedId} `,
		};

		return await res.status(201).json({ toast, data });
	} catch (error) {
		await handleError({ error, res });
	}
}

export async function remove(req, res, next) {
	if (!(await validateRequest(req, next))) return;

	const piPromise = db
		.delete(pi)
		.where(eq(pi.uuid, req.params.uuid))
		.returning({
			deletedId: sql`concat('PI', to_char(pi.created_at, 'YY'), '-', LPAD(pi.id::text, 4, '0'))`,
		});

	try {
		const data = await piPromise;
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
			uuid: pi.uuid,
			id: sql`concat('PI', to_char(pi.created_at, 'YY'), '-', LPAD(pi.id::text, 4, '0'))`,
			lc_uuid: pi.lc_uuid,
			lc_number: lc.lc_number,
			order_info_uuids: pi.order_info_uuids,
			marketing_uuid: pi.marketing_uuid,
			marketing_name: publicSchema.marketing.name,
			party_uuid: pi.party_uuid,
			party_name: publicSchema.party.name,
			merchandiser_uuid: pi.merchandiser_uuid,
			merchandiser_name: publicSchema.merchandiser.name,
			factory_uuid: pi.factory_uuid,
			factory_name: publicSchema.factory.name,
			bank_uuid: pi.bank_uuid,
			bank_name: bank.name,
			bank_swift_code: bank.swift_code,
			bank_address: bank.address,
			factory_address: publicSchema.factory.address,
			validity: pi.validity,
			payment: pi.payment,
			created_by: pi.created_by,
			created_by_name: hrSchema.users.name,
			created_at: pi.created_at,
			updated_at: pi.updated_at,
			remarks: pi.remarks,
		})
		.from(pi)
		.leftJoin(hrSchema.users, eq(pi.created_by, hrSchema.users.uuid))
		.leftJoin(
			publicSchema.marketing,
			eq(pi.marketing_uuid, publicSchema.marketing.uuid)
		)
		.leftJoin(
			publicSchema.party,
			eq(pi.party_uuid, publicSchema.party.uuid)
		)
		.leftJoin(
			publicSchema.merchandiser,
			eq(pi.merchandiser_uuid, publicSchema.merchandiser.uuid)
		)
		.leftJoin(
			publicSchema.factory,
			eq(pi.factory_uuid, publicSchema.factory.uuid)
		)
		.leftJoin(bank, eq(pi.bank_uuid, bank.uuid))
		.leftJoin(lc, eq(pi.lc_uuid, lc.uuid))
		.orderBy(desc(pi.created_at));

	const toast = {
		status: 200,
		type: 'select_all',
		message: 'Pi list',
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

	const piPromise = db
		.select({
			uuid: pi.uuid,
			id: sql`concat('PI', to_char(pi.created_at, 'YY'), '-', LPAD(pi.id::text, 4, '0'))`,
			lc_uuid: pi.lc_uuid,
			lc_number: lc.lc_number,
			order_info_uuids: pi.order_info_uuids,
			marketing_uuid: pi.marketing_uuid,
			marketing_name: publicSchema.marketing.name,
			party_uuid: pi.party_uuid,
			party_name: publicSchema.party.name,
			merchandiser_uuid: pi.merchandiser_uuid,
			merchandiser_name: publicSchema.merchandiser.name,
			factory_uuid: pi.factory_uuid,
			factory_name: publicSchema.factory.name,
			bank_uuid: pi.bank_uuid,
			bank_name: bank.name,
			bank_swift_code: bank.swift_code,
			bank_address: bank.address,
			factory_address: publicSchema.factory.address,
			validity: pi.validity,
			payment: pi.payment,
			created_by: pi.created_by,
			created_by_name: hrSchema.users.name,
			created_at: pi.created_at,
			updated_at: pi.updated_at,
			remarks: pi.remarks,
		})
		.from(pi)
		.leftJoin(hrSchema.users, eq(pi.created_by, hrSchema.users.uuid))
		.leftJoin(
			publicSchema.marketing,
			eq(pi.marketing_uuid, publicSchema.marketing.uuid)
		)
		.leftJoin(
			publicSchema.party,
			eq(pi.party_uuid, publicSchema.party.uuid)
		)
		.leftJoin(
			publicSchema.merchandiser,
			eq(pi.merchandiser_uuid, publicSchema.merchandiser.uuid)
		)
		.leftJoin(
			publicSchema.factory,
			eq(pi.factory_uuid, publicSchema.factory.uuid)
		)
		.leftJoin(bank, eq(pi.bank_uuid, bank.uuid))
		.leftJoin(lc, eq(pi.lc_uuid, lc.uuid))
		.where(eq(pi.uuid, req.params.uuid));

	try {
		const data = await piPromise;
		const toast = {
			status: 200,
			type: 'select',
			message: 'Pi',
		};
		return res.status(200).json({ toast, data: data[0] });
	} catch (error) {
		await handleError({ error, res });
	}
}

export async function selectPiDetailsByPiUuid(req, res, next) {
	if (!validateRequest(req, next)) return;

	const { pi_uuid } = req.params;

	try {
		const api = await createApi(req);
		const fetchData = async (endpoint) =>
			await api
				.get(`${endpoint}/${pi_uuid}`)
				.then((response) => response);

		const [pi, pi_entry] = await Promise.all([
			fetchData('/commercial/pi'),
			fetchData('/commercial/pi-entry/by'),
		]);

		const response = {
			...pi?.data?.data,
			pi_entry: pi_entry?.data?.data || [],
		};

		const toast = {
			status: 200,
			type: 'select',
			msg: 'Recipe Details Full',
		};

		res.status(200).json({ toast, data: response });
	} catch (error) {
		await handleError({ error, res });
	}
}

export async function selectPiUuidByPiId(req, res, next) {
	if (!validateRequest(req, next)) return;

	const { pi_id } = req.params;

	const piPromise = db
		.select({
			uuid: pi.uuid,
		})
		.from(pi)
		.where(eq(pi.id, sql`split_part(${pi_id}, '-', 2)::int`));

	try {
		const data = await piPromise;
		const toast = {
			status: 200,
			type: 'select',
			message: 'Pi uuid',
		};

		res.status(200).json({ toast, data: data[0] });
	} catch (error) {
		await handleError({ error, res });
	}
}

export async function selectPiDetailsByPiId(req, res, next) {
	if (!validateRequest(req, next)) return;

	const { pi_id } = req.params;

	const api = await createApi(req);

	const fetchPiUuid = async () =>
		await api
			.get(`/commercial/pi-uuid/${pi_id}`)
			.then((response) => response);

	const piUuid = await fetchPiUuid();

	try {
		const api = await createApi(req);
		const fetchData = async (endpoint) =>
			await api
				.get(`${endpoint}/${piUuid.data.data.uuid}`)
				.then((response) => response);

		const [pi, pi_entry] = await Promise.all([
			fetchData('/commercial/pi'),
			fetchData('/commercial/pi-entry/by'),
		]);

		const response = {
			...pi?.data?.data,
			pi_entry: pi_entry?.data?.data || [],
		};

		const toast = {
			status: 200,
			type: 'select',
			msg: 'Recipe Details Full',
		};

		res.status(200).json({ toast, data: response });
	} catch (error) {
		await handleError({ error, res });
	}
}

export async function updatePiPutLcByPiUuid(req, res, next) {
	if (!(await validateRequest(req, next))) return;

	const { pi_uuid } = req.params;

	const { lc_uuid } = req.body;

	const piPromise = db
		.update(pi)
		.set({ lc_uuid })
		.where(eq(pi.uuid, pi_uuid))
		.returning({
			updatedId: sql`concat('PI', to_char(pi.created_at, 'YY'), '-', LPAD(pi.id::text, 4, '0'))`,
		});

	try {
		const data = await piPromise;
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

export async function updatePiToNullByPiUuid(req, res, next) {
	if (!(await validateRequest(req, next))) return;

	const { pi_uuid } = req.params;

	const piPromise = db
		.update(pi)
		.set({ lc_uuid: null })
		.where(eq(pi.uuid, pi_uuid))
		.returning({
			updatedId: sql`concat('PI', to_char(pi.created_at, 'YY'), '-', LPAD(pi.id::text, 4, '0'))`,
		});

	try {
		const data = await piPromise;
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

export async function selectPiByLcUuid(req, res, next) {
	if (!(await validateRequest(req, next))) return;

	const { lc_uuid } = req.params;

	const piPromise = db
		.select({
			uuid: pi.uuid,
			id: sql`concat('PI', to_char(pi.created_at, 'YY'), '-', LPAD(pi.id::text, 4, '0'))`,
			lc_uuid: pi.lc_uuid,
			lc_number: lc.lc_number,
			order_info_uuids: pi.order_info_uuids,
			marketing_uuid: pi.marketing_uuid,
			marketing_name: publicSchema.marketing.name,
			party_uuid: pi.party_uuid,
			party_name: publicSchema.party.name,
			merchandiser_uuid: pi.merchandiser_uuid,
			merchandiser_name: publicSchema.merchandiser.name,
			factory_uuid: pi.factory_uuid,
			factory_name: publicSchema.factory.name,
			bank_uuid: pi.bank_uuid,
			bank_name: bank.name,
			bank_swift_code: bank.swift_code,
			bank_address: bank.address,
			factory_address: publicSchema.factory.address,
			validity: pi.validity,
			payment: pi.payment,
			created_by: pi.created_by,
			created_by_name: hrSchema.users.name,
			created_at: pi.created_at,
			updated_at: pi.updated_at,
			remarks: pi.remarks,
		})
		.from(pi)
		.leftJoin(hrSchema.users, eq(pi.created_by, hrSchema.users.uuid))
		.leftJoin(
			publicSchema.marketing,
			eq(pi.marketing_uuid, publicSchema.marketing.uuid)
		)
		.leftJoin(
			publicSchema.party,
			eq(pi.party_uuid, publicSchema.party.uuid)
		)
		.leftJoin(
			publicSchema.merchandiser,
			eq(pi.merchandiser_uuid, publicSchema.merchandiser.uuid)
		)
		.leftJoin(
			publicSchema.factory,
			eq(pi.factory_uuid, publicSchema.factory.uuid)
		)
		.leftJoin(bank, eq(pi.bank_uuid, bank.uuid))
		.leftJoin(lc, eq(pi.lc_uuid, lc.uuid))
		.where(eq(pi.lc_uuid, lc_uuid));

	const toast = {
		status: 200,
		type: 'select',
		message: 'Pi',
	};

	handleResponse({
		promise: piPromise,
		res,
		next,
		...toast,
	});
}
