import { atom } from 'recoil';
import { recoilPersist } from 'recoil-persist';

function getStorage() {
    if (typeof window!== 'undefined') {
      return window.localStorage; 
    }
    return undefined;
}


const { persistAtom } = recoilPersist({
    key: 'pushLocal',
    storage: getStorage(),
    converter: JSON,
});

const pushUser = atom({
    key: 'pushUser',
    default: {
        initializedUser: null,
        userChats: null,
    },
    effects_UNSTABLE: [persistAtom],
});

const PushStore = {
    pushUser
}

export default PushStore;
