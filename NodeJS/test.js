const CF_INSTANCE_INDEX = process.env.CF_INSTANCE_INDEX !== undefined ? process.env.CF_INSTANCE_INDEX : 'LOCAL SYSTEM'

const cache_file = {
    "MY_CACHE1": "OBJECT1",
    "MY_CACHE2": "OBJECT2"
}

exports.current = (req, res) => {
     return res.status(201).json({
         "Instance": CF_INSTANCE_INDEX,
         "Cache Object": cache_file
     });
}

exports.update = (req, res) => {
    cache_file.MY_CACHE3 = req.body.MY_CACHE;
    return res.status(201).json({
        "Instance": CF_INSTANCE_INDEX,
        "Cache Object": cache_file
    });
}

exports.refresh = async (req, res) => {
    // Update the current object in all instance that it hits
    console.log(req.body);
    let instance = 0
    const HTTP_STATUS = 200
    try {
        const vcap = process.env.VCAP_APPLICATION;
        console.log(vcap)
        const GUID = vcap.application_id;
        const APPLICATION_URL = vcap.application_uris
        const url = `https://${APPLICATION_URL}/api/v1/refresh_all`;
        while (HTTP_STATUS===200) {
            console.log(`Refresh Instance: ${instance} on ${url}`);
            const options = {
                method: 'POST',
                url,
                json: true,
                headers: {
                    'Content-Type': "application/json",
                    'X-CF-APP-INSTANCE': `${GUID}:${instance}`,
                    'cache-control': "no-cache",
                },
                body: qqiQuery,
                timeout: timeout
            };

            const r = await request(options);
            HTTP_STATUS = r.status_code;
            instance = instance + 1;
        }
    return res.status(201).json({
        'Refreshing': "Done",
        "Instances_Refreshed": instance - 1
    });
    } catch(error){
        console.error(error);

    }
}

// Add your Function that Refresh the cache on one instacne
exports.refresh_all = (req, res) => {
cache_file['MY_CACHE3'] = req.json['MY_CACHE']
 return res.status(201).json({
     'Refreshing': "Instance",
 });
}
