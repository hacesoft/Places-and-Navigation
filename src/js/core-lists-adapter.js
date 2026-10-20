(function () {
  'use strict';
  const NS = 'hc_navigation';
  const tr = text => typeof window.t === 'function' ? window.t(NS, text) : text;

  window.HcNavigationListsAdapter = function (core, getState, getUserId) {
    const shareKeys = new Map();
    let nextShareKey = 0;
    const body = options => options.body ? JSON.parse(options.body) : {};
    const segments = path => path.split('?')[0].split('/').filter(Boolean).map(decodeURIComponent);
    const listIdFor = place => String(place?._coreListId || place?.list_id || '');
    const fromCoreList = list => ({
      id: list.id, name: ['No list', 'Bez seznamu'].includes(list.title) ? tr('No list') : list.title, icon: list.icon || '📁', parent_id: list.parent_id,
      archived: list.archived ? 1 : 0, owner_uid: list.owner,
      _access: list.permission, _shared: list.permission !== 'owner',
    });
    const fromCorePlace = (place, list, direct = false) => ({
      id: place.id, list_id: direct ? null : (place.list_id || list?.id || null),
      _coreListId: place.list_id || list?.id || null,
      owner_uid: list?.owner || '', name: place.name,
      latitude: place.lat, longitude: place.lon, note: place.note || '',
      favorite: place.favorite ? 1 : 0, icon: place.icon || '📍', position: place.position || 0,
      _access: place.permission || list?.permission || 'read',
      _shared: direct || (place.permission || list?.permission) !== 'owner',
    });
    const toCorePlace = value => ({
      name: String(value.name || '').trim(), lat: Number(value.latitude), lon: Number(value.longitude),
      note: String(value.note || ''), color: '#3388ff',
      favorite: !!value.favorite, icon: String(value.icon || '📍'), sourceApp: NS,
      position: Number.isInteger(value.position) ? value.position : 0,
    });
    async function defaultList() {
      const lists = await core.lists.list(NS);
      const mine = lists.filter(list => list.owner === getUserId());
      return mine.find(list => ['No list', 'Bez seznamu'].includes(list.title))
        || await core.lists.create(NS, 'No list', mine.length, null, '📌');
    }
    function placeById(id) {
      const place = getState().places.find(item => String(item.id) === id);
      if (!place) throw new Error(tr('Place not found.'));
      return place;
    }
    async function bootstrap() {
      const lists = await core.lists.list(NS);
      const placesByList = await Promise.all(lists.map(list => core.lists.places(NS, list.id)));
      const ownAndShared = placesByList.flatMap((places, index) => places.map(place => fromCorePlace(place, lists[index])));
      const individual = (await core.lists.sharedPlaces(NS)).map(place => fromCorePlace(place, null, true));
      return { lists: lists.map(fromCoreList), places: ownAndShared.concat(individual), uid: getUserId() };
    }
    async function saveOrder(value) {
      if (!['list', 'place'].includes(value.objectType) || !Array.isArray(value.orderedIds)) throw new Error(tr('Invalid order.'));
      const state = getState();
      for (const [position, id] of value.orderedIds.entries()) {
        if (value.objectType === 'list') {
          const list = state.lists.find(item => item.id === id);
          if (list?._access === 'owner') await core.lists.update(NS, id, { position });
        } else {
          const place = state.places.find(item => item.id === id);
          if (place?._access === 'owner') await core.lists.updatePlace(NS, listIdFor(place), id, { position });
        }
      }
      return { ok: true };
    }
    async function shares(type, id) {
      const listId = type === 'place' ? listIdFor(placeById(id)) : id;
      const records = type === 'place'
        ? await core.lists.placeShares(NS, listId, id)
        : await core.lists.shares(NS, listId);
      return { shares: records.map(record => {
        const key = 'share_' + (++nextShareKey);
        shareKeys.set(key, { type, id, listId, targetType: record.target_type, targetId: record.target_id });
        return { id: key, recipient_type: record.target_type, recipient_id: record.target_id, permission: record.permission };
      }) };
    }
    async function handle(path, options = {}) {
      const parts = segments(path), method = options.method || 'GET', value = body(options);
      if (path === '/api/bootstrap' && method === 'GET') return bootstrap();
      if (path === '/api/order' && method === 'PUT') return saveOrder(value);
      if (parts[0] !== 'api') throw new Error(tr('Invalid Navigation request.'));
      if (parts[1] === 'lists') {
        if (parts.length === 2 && method === 'POST') {
          const list = await core.lists.create(NS, value.name, getState().lists.length, value.parentId || null, value.icon || '📁');
          return { ok: true, id: list.id };
        }
        const id = parts[2];
        if (id && method === 'PUT') {
          await core.lists.update(NS, id, { title: value.name, icon: value.icon || '📁', archived: !!value.archived,
            ...(Object.hasOwn(value, 'parentId') ? { parent_id: value.parentId || null } : {}) });
          return { ok: true };
        }
        if (id && method === 'DELETE') {
          await core.lists.update(NS, id, { archived: true });
          return { ok: true };
        }
      }
      if (parts[1] === 'places') {
        if (parts.length === 2 && method === 'POST') {
          const listId = value.listId || (await defaultList()).id;
          const place = await core.lists.addPlace(NS, listId, toCorePlace(value));
          return { ok: true, id: place.id };
        }
        const id = parts[2];
        if (id && method === 'PUT') {
          const old = placeById(id);
          let listId = listIdFor(old);
          const targetId = value.listId || (old._shared ? listId : (await defaultList()).id);
          if (listId !== targetId) {
            await core.lists.movePlace(NS, listId, id, targetId);
            listId = targetId;
          }
          await core.lists.updatePlace(NS, listId, id, toCorePlace({ ...value, position: old.position }));
          return { ok: true };
        }
        if (id && method === 'DELETE') {
          await core.lists.removePlace(NS, listIdFor(placeById(id)), id);
          return { ok: true };
        }
      }
      if (parts[1] === 'shares') {
        if (parts.length === 4 && method === 'GET') return shares(parts[2], parts[3]);
        if (parts.length === 2 && method === 'POST') {
          const id = String(value.objectId);
          if (value.objectType === 'place') {
            await core.lists.sharePlace(NS, listIdFor(placeById(id)), id, value.recipientType, value.recipientId, value.permission);
          } else if (value.objectType === 'list') {
            await core.lists.share(NS, id, value.recipientType, value.recipientId, value.permission);
          } else throw new Error(tr('Invalid share type.'));
          return { ok: true };
        }
        if (parts.length === 3 && method === 'DELETE') {
          const share = shareKeys.get(parts[2]);
          if (!share) throw new Error(tr('Share not found.'));
          if (share.type === 'place') await core.lists.unsharePlace(NS, share.listId, share.id, share.targetType, share.targetId);
          else await core.lists.unshare(NS, share.listId, share.targetType, share.targetId);
          shareKeys.delete(parts[2]);
          return { ok: true };
        }
      }
      throw new Error(tr('Unsupported Navigation list request:') + ' ' + method + ' ' + path);
    }
    return Object.freeze({ handle });
  };
})();
