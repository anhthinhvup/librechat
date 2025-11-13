import React from 'react';
import { useLocalize } from '~/hooks';
import { useGetEndpointsQuery } from '~/data-provider';
import { EModelEndpoint } from 'librechat-data-provider';

export default function Endpoints() {
  const localize = useLocalize();
  const { data: endpointsConfig } = useGetEndpointsQuery();

  return (
    <div className="flex flex-col gap-6">
      <div className="flex flex-col gap-2">
        <h3 className="text-lg font-medium text-text-primary">
          {localize('com_nav_setting_endpoints')}
        </h3>
        <p className="text-sm text-text-secondary">
          {localize('com_nav_setting_endpoints_description')}
        </p>
      </div>

      <div className="flex flex-col gap-4">
        {Object.keys(endpointsConfig || {}).map((endpoint) => {
          const config = endpointsConfig?.[endpoint as EModelEndpoint];
          return (
            <div key={endpoint} className="rounded-lg border border-border-light bg-surface-secondary p-4">
              <div className="flex items-center justify-between">
                <div className="flex flex-col gap-1">
                  <h4 className="font-medium text-text-primary capitalize">
                    {endpoint.replace(/([A-Z])/g, ' $1').trim()}
                  </h4>
                  <p className="text-sm text-text-secondary">
                    {config?.models?.default?.length || 0} models available
                  </p>
                </div>
                <div className="flex items-center gap-2">
                  <span className={`px-2 py-1 rounded text-xs ${
                    config?.apiKey ? 'bg-green-100 text-green-800' : 'bg-red-100 text-red-800'
                  }`}>
                    {config?.apiKey ? 'Configured' : 'Not Configured'}
                  </span>
                </div>
              </div>
              {config?.models?.default && (
                <div className="mt-3">
                  <p className="text-sm text-text-secondary mb-2">Available Models:</p>
                  <div className="flex flex-wrap gap-1">
                    {config.models.default.slice(0, 3).map((model) => (
                      <span key={model} className="px-2 py-1 bg-surface-tertiary rounded text-xs">
                        {model}
                      </span>
                    ))}
                    {config.models.default.length > 3 && (
                      <span className="px-2 py-1 bg-surface-tertiary rounded text-xs">
                        +{config.models.default.length - 3} more
                      </span>
                    )}
                  </div>
                </div>
              )}
            </div>
          );
        })}
        
        {(!endpointsConfig || Object.keys(endpointsConfig).length === 0) && (
          <div className="text-center py-8">
            <p className="text-text-secondary mb-4">
              {localize('com_nav_setting_endpoints_empty')}
            </p>
            <p className="text-sm text-text-tertiary">
              {localize('com_nav_setting_endpoints_empty_description')}
            </p>
          </div>
        )}
      </div>
    </div>
  );
}
