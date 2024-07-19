"use client"

const ConnectKitAvatarConfig = ({ address, size, radius }) => {

 return (
    <div
      style={{
        overflow: "hidden",
        borderRadius: radius,
        height: size,
        width: size,
        position: 'relative',
      }}
    >\
      {<img src={`https://api.dicebear.com/7.x/thumbs/svg?seed=Slash:${address}`} alt={address} width="100%" height="100%" />}
    </div>
 );
};

export default ConnectKitAvatarConfig;
