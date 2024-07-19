export const tap = async (value, cb) => {
    await cb(value);
    return value;
};
